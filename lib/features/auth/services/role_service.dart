import '../../../shared/models/role.dart';
import '../../../shared/services/http_client.dart';
import '../../../shared/config/api_config.dart';

class RoleService {
  const RoleService();

  /// Fetch available roles for a school/branch
  /// Uses branch_id to scope roles so only roles for that branch show up.
  Future<List<Role>> fetchRoles({String? schoolId, String? branchId}) async {
    try {
      // Use branchId if provided, otherwise fall back to schoolId
      final idToSend = branchId ?? schoolId;

      print('🔍 RoleService: Fetching roles for branch_id: $idToSend');

      final response = await HttpClient().post(
        ApiConfig.getRoleList,
        body: {if (idToSend != null) 'branch_id': idToSend},
        requireAuth: false,
      );

      print('📦 RoleService: API Response status: ${response['status']}');
      print('📦 RoleService: API Response message: ${response['message']}');

      if (response['status'] == 'success' && response['data'] != null) {
        final rolesData = response['data'] as List<dynamic>? ?? [];
        print('✅ RoleService: Found ${rolesData.length} roles from API');

        final roles = rolesData
            .map((roleData) => Role.fromApiResponse(roleData))
            .toList();

        // Log each role for debugging
        for (var role in roles) {
          print('   - Role: ${role.name} (ID: ${role.id}, slug: ${role.slug})');
        }

        return roles;
      } else {
        print(
          '⚠️ RoleService: API returned no roles or error. Status: ${response['status']}, Message: ${response['message']}',
        );
        // If API doesn't return roles, return default roles
        return _getDefaultRoles();
      }
    } catch (e) {
      print('❌ RoleService: Error fetching roles: $e');
      print('   Stack trace: ${StackTrace.current}');
      // Return default roles if API fails
      return _getDefaultRoles();
    }
  }

  /// Get default roles if API is not available
  List<Role> _getDefaultRoles() {
    return [
      const Role(
        id: '1',
        name: 'Principal/Admin',
        slug: 'admin',
        description: 'School administrator',
      ),
      const Role(
        id: '2',
        name: 'Teacher',
        slug: 'teacher',
        description: 'Teaching staff',
      ),
      const Role(
        id: '3',
        name: 'Student',
        slug: 'student',
        description: 'Student',
      ),
      const Role(
        id: '4',
        name: 'Parent',
        slug: 'parent',
        description: 'Parent/Guardian',
      ),
    ];
  }
}
