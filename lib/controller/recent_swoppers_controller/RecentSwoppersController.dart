import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import '../../model/RecentSwoppersModel.dart';
import '../../view/network/ApiService.dart';
import '../../view/network/ApiUrls.dart';
import '../../view/utils/app_constants.dart';
import '../../view/utils/shared_pref/SharedPrefHelper.dart';

class RecentSwoppersController extends GetxController {
  var isLoading = false.obs;
  var recentSwoppers = <User>[].obs;
  var fetchRecentSwoppersLoader = false.obs;
  var useMockData = false.obs; // For testing purposes
  var isCreatingConnection = false.obs; // For connection creation loading state



  void getData()async{
    final firebaseId = await SharedPrefService.getString('firebase_id');
    final backendUserId = await SharedPrefService.getString('backend_user_id');
    if(backendUserId != null && firebaseId != null && firebaseId.isNotEmpty){
      fetchRecentSwoppers();
    }


  }
  @override
  void onInit() {
    super.onInit();

    getData();
  }

  Future<void> fetchRecentSwoppers() async {
    fetchRecentSwoppersLoader.value = true;
    
    try {
      log("🔄 Starting to fetch recent swoppers...");
      
      // For testing, you can set useMockData to true
      if (useMockData.value) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate API delay
        fetchRecentSwoppersLoader.value = false;
        log("⚠️ Using mock data, skipping API call");
        return;
      }

      final firebaseId = await SharedPrefService.getString('firebase_id');
      if (firebaseId == null || firebaseId.isEmpty) {
        SnackbarUtil.showError("Firebase ID not found");
        // Clear existing data if no firebase ID
        recentSwoppers.clear();
        fetchRecentSwoppersLoader.value = false;
        log("❌ No Firebase ID found, cleared connections data");
        return;
      }

      log("🔍 Firebase ID found: $firebaseId");

      // Step 1: Fetch connections
      final connectionsResponse = await ApiService.get(ApiUrls.connections);
      log("📡 Fetch Connections Response Status: ${connectionsResponse?.statusCode}");
      log("📡 Fetch Connections Response Body: ${connectionsResponse?.body}");

      if (connectionsResponse == null || connectionsResponse.statusCode != 200) {
        // SnackbarUtil.showError("Failed to load connections");
        fetchRecentSwoppersLoader.value = false;
        log("❌ Failed to fetch connections: ${connectionsResponse?.statusCode}");
        return;
      }

      try {
        final connectionsData = jsonDecode(connectionsResponse.body);
        final connectionsModel = ConnectionsModel.fromJson(connectionsData);
        
        log("✅ Parsed connections data: ${connectionsModel.connections.length} connections found");
        
        // Step 2: Fetch user details for each connection (in parallel) and store connection ID
        final futures = connectionsModel.connections.map((connection) async {
          try {
            log("🔍 Fetching user details for connection ID: ${connection.id}, User ID: ${connection.id}");
            
            // Use backend user ID for user details endpoint
            final endpoint = '${ApiUrls.userDetails}${connection.connectionUid.toString()}';
            final userResponse = await ApiService.get(endpoint);
            log("📡 Fetch User Details Response for ${connection.connectionUid.toString()}: ${userResponse?.statusCode}");

            if (userResponse != null && userResponse.statusCode == 200) {
              final body = userResponse.body.trim();
              // Guard against HTML error pages
              if (body.startsWith('<!DOCTYPE html>') || body.startsWith('<html>')) {
                log("❌ Expected JSON but received HTML for userId ${connection.userId.toString()}");
                return null;
              }

              final userData = jsonDecode(body);
              final userDetailsModel = UserDetailsModel.fromJson(userData);
              // Store the connection ID in the user object for removal
              userDetailsModel.user.connectionId = connection.id;
              log("✅ Successfully fetched user: ${userDetailsModel.user.name} (@${userDetailsModel.user.username})");
              return userDetailsModel.user;
            }
          } catch (e) {
            log("❌ Error fetching user details for connection ID: ${connection.id}, User ID: ${connection.userId}: $e");
          }
          return null;
        }).toList();

        final results = await Future.wait(futures);
        final validUsers = results.whereType<User>().toList();
        
        log("✅ Fetched ${validUsers.length} valid users out of ${connectionsModel.connections.length} connections");
        
        // Update the observable list
        recentSwoppers.value = validUsers;
        
        log("✅ Recent swoppers list updated with ${recentSwoppers.length} users");
        
      } catch (e) {
        // SnackbarUtil.showError("Failed to parse connections data");
        log("❌ JSON decode error: $e");
      }
      
    } catch (e) {
      // SnackbarUtil.showError("Error fetching recent swoppers: $e");
      log("❌ Error fetching recent swoppers: $e");
    } finally {
      fetchRecentSwoppersLoader.value = false;
      log("🔄 Fetch recent swoppers completed");
    }
  }

  Future<bool> createConnection(String username) async {
    if (isCreatingConnection.value) {
      log("🔄 Connection creation already in progress...");
      return false;
    }

    isCreatingConnection.value = true;
    
    try {
      log("🔗 Creating connection with username: $username");
      
      // Check if connection already exists
      final existingConnection = recentSwoppers.firstWhereOrNull((user) => user.username == username);
      if (existingConnection != null) {
        log("ℹ️ Connection already exists with @$username");
        SnackbarUtil.showInfo("You are already connected with @$username");
        return true;
      }

      // Try to get user details, but don't fail if we can't
      User? user = await getUserByUsername(username);
      if (user == null) {
        log("⚠️ User details not found for: $username, but proceeding with connection");
        // Create a minimal user object for the connection
        user = User(
          id: '', // Will be set by server
          firebaseId: '',
          username: username,
          bio: null,
          profileUrl: null,
          name: username, // Use username as name if we don't have the real name
          age: null,
          email: '',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          connectionId: null, // Will be set when connection is created
        );
      }

      final body = {
        "username": username,
      };

      log("📡 Sending createConnection API request...");
      log("📡 Request body: $body");
      final response = await ApiService.post(ApiUrls.connections, body);
      log("Create Connection Response: ${response?.body}");

      if (response != null && response.statusCode == 200) {
        log("✅ Connection created successfully");
        
        // Try to get connection ID from response
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['connection_id'] != null) {
            user.connectionId = responseData['connection_id'].toString();
          }
        } catch (e) {
          log("⚠️ Could not parse connection ID from response: $e");
        }
        
        // Instead of adding the minimal user object, refresh the connections
        // This will fetch the actual user data from the server
        log("🔄 Refreshing connections to get actual user data...");
        await fetchRecentSwoppers();
        
        // Show success message
        SnackbarUtil.showSuccess("Connected with @$username successfully!");
        return true;
      } else if (response != null && response.statusCode == 409) {
        log("ℹ️ Connection already exists (409 status)");
        SnackbarUtil.showInfo("You are already connected with @$username");
        return true;
      } else if (response != null && response.statusCode == 400) {
        log("❌ Validation error (400): ${response.body}");
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            SnackbarUtil.showError(errorData['message']);
            return false;
          }
        } catch (e) {
          log("❌ Error parsing validation response: $e");
        }
        SnackbarUtil.showError("Invalid username format. Please check the NFC card data.");
        return false;
      } else if (response != null && response.statusCode == 404) {
        log("❌ User not found on server (404)");
        SnackbarUtil.showError("User @$username not found on the server. Please verify the username.");
        return false;
      } else {
        log("❌ Failed to create connection. Status: ${response?.statusCode}");
        log("❌ Response body: ${response?.body}");
        SnackbarUtil.showError("Failed to create connection with @$username. Please try again.");
        return false;
      }
    } catch (e) {
      log("❌ Error creating connection: $e");
      SnackbarUtil.showError("Error creating connection: $e");
      return false;
    } finally {
      isCreatingConnection.value = false;
    }
  }

  Future<void> removeConnection(String connectionId) async {
    try {
      // For mock data, just remove from local list
      if (useMockData.value) {
        recentSwoppers.removeWhere((user) => user.connectionId == connectionId);
        SnackbarUtil.showSuccess("Removed from connections");
        return;
      }

      final deleteUrl = '${ApiUrls.connections}$connectionId';
      log("🗑️ Deleting connection with URL: $deleteUrl");
      final response = await ApiService.delete(deleteUrl);
      log("Remove Connection Response: ${response?.body}");
      log("Remove Connection Status Code: ${response?.statusCode}");

      if (response != null && response.statusCode == 200) {
        // Remove from local list using connectionId
        recentSwoppers.removeWhere((user) => user.connectionId == connectionId);
        SnackbarUtil.showSuccess("Removed from connections");
        
        // Optionally refresh the connections to ensure data consistency
        // await fetchRecentSwoppers();
      } else {
        SnackbarUtil.showError("Failed to remove connection");
      }
    } catch (e) {
      log("❌ Error removing connection: $e");
      SnackbarUtil.showError("Failed to remove connection");
    }
  }

  void clearAllConnections() {
    recentSwoppers.clear();
  }

  // Method to clear all data on logout
  void clearAllDataOnLogout() {
    log("🧹 Clearing all connection data on logout...");
    recentSwoppers.clear();
    isLoading.value = false;
    fetchRecentSwoppersLoader.value = false;
    isCreatingConnection.value = false;
    useMockData.value = false;
    log("✅ All connection data cleared");
  }

  // Method to toggle mock data for testing
  void toggleMockData() {
    useMockData.value = !useMockData.value;
    fetchRecentSwoppers();
  }

  // Method to get user by username (for NFC integration)
  Future<User?> getUserByUsername(String username) async {
    try {
      log("🔍 Looking up user details for username: $username");
      
      // Since we don't have a username search endpoint, we'll create a minimal user object
      // The connection API will handle the actual user lookup and validation
      // This ensures that when someone touches your device with NFC, their data is fetched correctly
      
      log("⚠️ No username search endpoint available, creating minimal user object for: $username");
      log("⚠️ The connection API will handle user validation and data fetching");
      
      // Create a minimal user object that will be populated by the server
      // This prevents the issue where your own data was being returned
      return User(
        id: '', // Will be set by server when connection is created
        firebaseId: '',
        username: username,
        bio: null,
        profileUrl: null,
        name: username, // Use username as name initially, will be updated by server
        age: null,
        email: '',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        connectionId: null, // Will be set when connection is created
      );
      
    } catch (e) {
      log("❌ Error getting user by username: $e");
      return null;
    }
  }

  // Method to check if user is already connected
  bool isUserConnected(String username) {
    return recentSwoppers.any((user) => user.username == username);
  }

  // Method to get connection count
  int get connectionCount => recentSwoppers.length;

  // Method to refresh connections (useful after NFC connections)
  Future<void> refreshConnections() async {
    log("🔄 Refreshing connections...");
    await fetchRecentSwoppers();
  }

  // Method to test different API endpoints for getting user details
  Future<void> testApiEndpoints() async {
    log("🧪 Testing API endpoints for user details...");
    
    String testUsername = "ranga011"; // Use the username that was failing
    
    // Test current user data
    log("🔍 Testing current user data from AppConst...");
    log("📡 Current username: ${AppConst.USER_NAME}");
    log("📡 Current full name: ${AppConst.fullName}");
    log("📡 Current email: ${AppConst.EMAIL}");
    log("📡 Current bio: ${AppConst.BIO}");
    log("📡 Current profile: ${AppConst.USER_PROFILE}");
    
    // Test backend user ID
    final backendUserId = await SharedPrefService.getString('backend_user_id');
    log("📡 Backend user ID: $backendUserId");
    
    // Test firebase ID
    final firebaseId = await SharedPrefService.getString('firebase_id');
    log("📡 Firebase ID: $firebaseId");
    
    // Test the actual user details endpoint
    if (backendUserId != null && backendUserId.isNotEmpty) {
      try {
        final endpoint = '${ApiUrls.userDetails}$backendUserId';
        log("🔍 Testing endpoint: $endpoint");
        final response = await ApiService.get(endpoint);
        
        if (response != null) {
          log("📡 Response status: ${response.statusCode}");
          log("📡 Response body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}");
          
          if (response.statusCode == 200) {
            if (response.body.trim().startsWith('<!DOCTYPE html>') || 
                response.body.trim().startsWith('<html>')) {
              log("❌ Endpoint $endpoint returned HTML error page");
            } else {
              try {
                final userData = jsonDecode(response.body);
                log("✅ Endpoint $endpoint returned valid JSON!");
                log("✅ User data: $userData");
              } catch (jsonError) {
                log("❌ Endpoint $endpoint returned invalid JSON: $jsonError");
              }
            }
          } else {
            log("❌ Endpoint $endpoint returned status ${response.statusCode}");
          }
        } else {
          log("❌ Endpoint $endpoint returned null response");
        }
      } catch (e) {
        log("❌ Error testing endpoint: $e");
      }
    } else {
      log("❌ No backend user ID available for testing");
    }
    
    log("🧪 API endpoint testing completed");
  }

  // Method to handle NFC-triggered connections
  Future<void> handleNfcConnection(String username) async {
    log("🔗 NFC Connection triggered for username: $username");
    
    try {
      // Check if user is already connected
      if (isUserConnected(username)) {
        SnackbarUtil.showInfo("You are already connected with @$username");

        log("ℹ️ User @$username is already connected");
        return;
      }
      
      log("🔄 Starting connection creation for @$username...");
      
      // Create connection using existing logic
      final success = await createConnection(username);
      
      if (success) {
        log("✅ NFC connection created successfully for @$username");
        
        // Refresh the connections to show the actual user data
        log("🔄 Refreshing connections after NFC connection...");
        await fetchRecentSwoppers();
        
        // Verify the user was added to the list
        final isNowConnected = isUserConnected(username);
        log("🔍 Verification: User @$username is now connected: $isNowConnected");
        log("🔍 Total connections: ${recentSwoppers.length}");
        
        // Show success message
        SnackbarUtil.showSuccess("NFC connection successful! @$username added to your connections.");
        
        // Force UI update
        recentSwoppers.refresh();
        
      } else {
        log("❌ Failed to create NFC connection for @$username");
        SnackbarUtil.showError("Failed to create NFC connection with @$username. Please try again.");
      }
    } catch (e) {
      log("❌ Error in handleNfcConnection: $e");
      SnackbarUtil.showError("Error creating NFC connection: $e");
    }
  }

  // Method to handle NFC connections with better error handling
  Future<void> handleNfcConnectionWithRetry(String username, {int maxRetries = 3}) async {
    log("🔗 NFC Connection with retry for username: $username");
    
    int retryCount = 0;
    bool success = false;
    
    while (retryCount < maxRetries && !success) {
      try {
        retryCount++;
        log("🔄 Attempt $retryCount of $maxRetries");
        
        success = await createConnection(username);
        
        if (success) {
          log("✅ NFC connection successful on attempt $retryCount");
          
          // Refresh connections to get actual user data
          await fetchRecentSwoppers();
          
          SnackbarUtil.showSuccess("Connected with @$username via NFC!");
          return;
        } else {
          log("❌ NFC connection failed on attempt $retryCount");
          
          if (retryCount < maxRetries) {
            log("⏳ Waiting before retry...");
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      } catch (e) {
        log("❌ Error on attempt $retryCount: $e");
        
        if (retryCount < maxRetries) {
          log("⏳ Waiting before retry...");
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
    
    if (!success) {
      log("❌ All retry attempts failed for @$username");
      SnackbarUtil.showError("Failed to connect with @$username after $maxRetries attempts. Please try again later.");
    }
  }
}
