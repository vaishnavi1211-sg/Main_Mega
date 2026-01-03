import 'package:flutter/material.dart';
import 'package:mega_pro/global/global_variables.dart';
import 'package:mega_pro/global/textstyles.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  String _selectedBranch = "All Branches";
  String _selectedDepartment = "All Departments";

  final List<Map<String, dynamic>> _branches = [
    {
      "name": "Pune Branch",
      "district": "Pune",
      "employees": 28,
      "manager": "Rajesh Kumar",
      "address": "Hadapsar, Pune",
      "performance": 4.6,
    },
    {
      "name": "Mumbai Branch",
      "district": "Mumbai",
      "employees": 35,
      "manager": "Priya Sharma",
      "address": "Andheri East, Mumbai",
      "performance": 4.8,
    },
  ];

  final List<Map<String, dynamic>> _employees = [
    {
      "id": "EMP-PN-001",
      "name": "Rajesh Kumar",
      "position": "Branch Manager",
      "department": "Management",
      "branch": "Pune Branch",
      "district": "Pune",
      "salary": 75000,
      "status": "Active",
      "performance": 4.8,
    },
    {
      "id": "EMP-MB-001",
      "name": "Priya Sharma",
      "position": "Branch Manager",
      "department": "Management",
      "branch": "Mumbai Branch",
      "district": "Mumbai",
      "salary": 80000,
      "status": "Active",
      "performance": 4.9,
    },
  ];

  List<Map<String, dynamic>> get _filteredEmployees {
    return _employees.where((e) {
      final branchMatch =
          _selectedBranch == "All Branches" || e["branch"] == _selectedBranch;
      final deptMatch =
          _selectedDepartment == "All Departments" ||
              e["department"] == _selectedDepartment;
      return branchMatch && deptMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          "Employee Management",
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.cardBg,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _branchOverview(),
            const SizedBox(height: 20),
            _filters(),
            const SizedBox(height: 20),
            _employeeList(),
          ],
        ),
      ),
    );
  }

  // ---------------- BRANCH OVERVIEW ----------------

  Widget _branchOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Branch Overview", style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _branches.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (_, i) => _branchCard(_branches[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _branchCard(Map<String, dynamic> branch) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softGreyBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            branch["name"],
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryBlue,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            branch["district"],
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.star,
                  size: 14, color: AppColors.ratingAmber),
              const SizedBox(width: 4),
              Text(
                branch["performance"].toString(),
                style: AppTextStyles.metricSuccess,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- FILTERS ----------------

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedBranch,
              decoration: _dropdownDecoration("Branch"),
              items: ["All Branches", "Pune Branch", "Mumbai Branch"]
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b, style: AppTextStyles.bodyRegular),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBranch = v!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: _dropdownDecoration("Department"),
              items: ["All Departments", "Marketing", "Production"]
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d, style: AppTextStyles.bodyRegular),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedDepartment = v!),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- EMPLOYEE LIST ----------------

  Widget _employeeList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _filteredEmployees.map(_employeeTile).toList(),
      ),
    );
  }

  Widget _employeeTile(Map<String, dynamic> e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softGreyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lightBlue,
            child: const Icon(Icons.person, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              e["name"],
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.star,
              size: 14, color: AppColors.ratingAmber),
          const SizedBox(width: 4),
          Text(
            e["performance"].toString(),
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowGrey,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  InputDecoration _dropdownDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.label,
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderGrey),
        ),
      );
}




// // import 'package:flutter/material.dart';

// // class EmployeesPage extends StatefulWidget {
// //   const EmployeesPage({super.key});

// //   @override
// //   State<EmployeesPage> createState() => _EmployeesPageState();
// // }

// // class _EmployeesPageState extends State<EmployeesPage> {
// //   String _selectedBranch = "All Branches";
// //   String _selectedDepartment = "All Departments";

// //   final List<Map<String, dynamic>> _branches = [
// //     {
// //       "name": "Pune Branch",
// //       "district": "Pune",
// //       "employees": 28,
// //       "manager": "Rajesh Kumar",
// //       "address": "Hadapsar, Pune",
// //       "performance": 4.6,
// //       "attendance": 96.2,
// //       "sales": 1250000,
// //       "activeProjects": 8
// //     },
// //     {
// //       "name": "Mumbai Branch",
// //       "district": "Mumbai",
// //       "employees": 35,
// //       "manager": "Priya Sharma",
// //       "address": "Andheri East, Mumbai",
// //       "performance": 4.8,
// //       "attendance": 97.8,
// //       "sales": 1850000,
// //       "activeProjects": 12
// //     },
// //     {
// //       "name": "Nagpur Branch",
// //       "district": "Nagpur",
// //       "employees": 18,
// //       "manager": "Amit Patel",
// //       "address": "Sitabuldi, Nagpur",
// //       "performance": 4.3,
// //       "attendance": 94.5,
// //       "sales": 850000,
// //       "activeProjects": 5
// //     },
// //     {
// //       "name": "Nashik Branch",
// //       "district": "Nashik",
// //       "employees": 22,
// //       "manager": "Sneha Reddy",
// //       "address": "College Road, Nashik",
// //       "performance": 4.5,
// //       "attendance": 95.8,
// //       "sales": 950000,
// //       "activeProjects": 7
// //     },
// //   ];

// //   final List<Map<String, dynamic>> _employees = [
// //     // Pune Branch Employees
// //     {
// //       "id": "EMP-PN-001",
// //       "name": "Rajesh Kumar",
// //       "position": "Branch Manager",
// //       "department": "Management",
// //       "branch": "Pune Branch",
// //       "district": "Pune",
// //       "salary": 75000,
// //       "joined": "15 Mar 2020",
// //       "status": "Active",
// //       "performance": 4.8,
// //       "attendance": 98.2,
// //       "phone": "+91 98765 43210",
// //       "email": "rajesh.k@pune.com"
// //     },
// //     {
// //       "id": "EMP-PN-002",
// //       "name": "Sanjay Gupta",
// //       "position": "Production Supervisor",
// //       "department": "Production",
// //       "branch": "Pune Branch",
// //       "district": "Pune",
// //       "salary": 35000,
// //       "joined": "20 Jun 2022",
// //       "status": "Active",
// //       "performance": 4.2,
// //       "attendance": 95.8,
// //       "phone": "+91 87654 32109",
// //       "email": "sanjay.g@pune.com"
// //     },
// //     {
// //       "id": "EMP-PN-003",
// //       "name": "Neha Joshi",
// //       "position": "Quality Inspector",
// //       "department": "Quality Control",
// //       "branch": "Pune Branch",
// //       "district": "Pune",
// //       "salary": 28000,
// //       "joined": "10 Jan 2023",
// //       "status": "Active",
// //       "performance": 4.1,
// //       "attendance": 94.5,
// //       "phone": "+91 76543 21098",
// //       "email": "neha.j@pune.com"
// //     },

// //     // Mumbai Branch Employees
// //     {
// //       "id": "EMP-MB-001",
// //       "name": "Priya Sharma",
// //       "position": "Branch Manager",
// //       "department": "Management",
// //       "branch": "Mumbai Branch",
// //       "district": "Mumbai",
// //       "salary": 80000,
// //       "joined": "05 Sep 2019",
// //       "status": "Active",
// //       "performance": 4.9,
// //       "attendance": 99.1,
// //       "phone": "+91 65432 10987",
// //       "email": "priya.s@mumbai.com"
// //     },
// //     {
// //       "id": "EMP-MB-002",
// //       "name": "Rahul Verma",
// //       "position": "Sales Executive",
// //       "department": "Sales",
// //       "branch": "Mumbai Branch",
// //       "district": "Mumbai",
// //       "salary": 32000,
// //       "joined": "12 Dec 2022",
// //       "status": "Active",
// //       "performance": 4.3,
// //       "attendance": 92.7,
// //       "phone": "+91 54321 09876",
// //       "email": "rahul.v@mumbai.com"
// //     },

// //     // Nagpur Branch Employees
// //     {
// //       "id": "EMP-NG-001",
// //       "name": "Amit Patel",
// //       "position": "Branch Manager",
// //       "department": "Management",
// //       "branch": "Nagpur Branch",
// //       "district": "Nagpur",
// //       "salary": 65000,
// //       "joined": "25 Feb 2021",
// //       "status": "Active",
// //       "performance": 4.4,
// //       "attendance": 97.3,
// //       "phone": "+91 32109 87654",
// //       "email": "amit.p@nagpur.com"
// //     },

// //     // Nashik Branch Employees
// //     {
// //       "id": "EMP-NS-001",
// //       "name": "Sneha Reddy",
// //       "position": "Branch Manager",
// //       "department": "Management",
// //       "branch": "Nashik Branch",
// //       "district": "Nashik",
// //       "salary": 68000,
// //       "joined": "30 Jul 2020",
// //       "status": "Active",
// //       "performance": 4.7,
// //       "attendance": 98.6,
// //       "phone": "+91 10987 65432",
// //       "email": "sneha.r@nashik.com"
// //     },

// //     // Bengaluru Branch Employees
// //     {
// //       "id": "EMP-BL-001",
// //       "name": "Arun Kumar",
// //       "position": "Branch Manager",
// //       "department": "Management",
// //       "branch": "Bengaluru Branch",
// //       "district": "Bengaluru Urban",
// //       "salary": 72000,
// //       "joined": "22 Oct 2020",
// //       "status": "Active",
// //       "performance": 4.6,
// //       "attendance": 97.8,
// //       "phone": "+91 98765 01234",
// //       "email": "arun.k@bengaluru.com"
// //     },
// //   ];

// //   List<Map<String, dynamic>> get _filteredEmployees {
// //     if (_selectedBranch == "All Branches" && _selectedDepartment == "All Departments") {
// //       return _employees;
// //     }
    
// //     return _employees.where((employee) {
// //       final branchMatch = _selectedBranch == "All Branches" || employee["branch"] == _selectedBranch;
// //       final deptMatch = _selectedDepartment == "All Departments" || employee["department"] == _selectedDepartment;
// //       return branchMatch && deptMatch;
// //     }).toList();
// //   }

// //   List<String> get _departments {
// //     final departments = _employees.map((e) => e["department"].toString()).toSet().toList();
// //     departments.insert(0, "All Departments");
// //     return departments;
// //   }

// //   List<String> get _branchNames {
// //     final branches = _branches.map((b) => b["name"].toString()).toList();
// //     branches.insert(0, "All Branches");
// //     return branches;
// //   }

// //   int get _totalEmployees {
// //     return _branches.fold<int>(0, (sum, branch) => sum + (branch["employees"] as int));
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFF9FAFB),
// //       appBar: AppBar(
// //         title: const Text("Employee Management",style: TextStyle(color: Colors.white),),
// //         backgroundColor: Colors.blue,
// //         elevation: 1,
// //         iconTheme: const IconThemeData(color: Colors.white,
        
// //       ),
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Branch Overview
// //             _buildBranchOverview(),
// //             const SizedBox(height: 20),

// //             // Filters
// //             _buildFilters(),
// //             const SizedBox(height: 20),

// //             // Employees List
// //             _buildEmployeesList(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildBranchOverview() {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.shade300,
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               const Text(
// //                 "Branch Overview",
// //                 style: TextStyle(
// //                   fontSize: 18,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Row(
// //                 children: [
// //                   const Icon(Icons.people, size: 16, color: Colors.blue),
// //                   const SizedBox(width: 4),
// //                   const Text(
// //                     "Total Employees: ",
// //                     style: TextStyle(fontSize: 12, color: Colors.grey),
// //                   ),
// //                   Text(
// //                     _totalEmployees.toString(),
// //                     style: const TextStyle(
// //                       fontSize: 12, 
// //                       fontWeight: FontWeight.bold, 
// //                       color: Colors.blue
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 16),
          
// //           // Branch Cards Grid - Fixed responsive layout
// //           LayoutBuilder(
// //             builder: (context, constraints) {
// //               final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
// //               return GridView.builder(
// //                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
// //                   crossAxisCount: crossAxisCount,
// //                   crossAxisSpacing: 12,
// //                   mainAxisSpacing: 12,
// //                   childAspectRatio: 1.4, // Increased to prevent overflow
// //                 ),
// //                 shrinkWrap: true,
// //                 physics: const NeverScrollableScrollPhysics(),
// //                 itemCount: _branches.length,
// //                 itemBuilder: (context, index) => _branchCard(_branches[index]),
// //               );
// //             },
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _branchCard(Map<String, dynamic> branch) {
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: Colors.grey.shade50,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey.shade200),
// //       ),
// //       child: Padding(
// //         padding: const EdgeInsets.all(12),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // Header with branch name and performance
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         _getShortBranchName(branch["name"]),
// //                         style: const TextStyle(
// //                           fontSize: 14,
// //                           fontWeight: FontWeight.bold,
// //                           color: Colors.blue,
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                         maxLines: 1,
// //                       ),
// //                       const SizedBox(height: 2),
// //                       Text(
// //                         branch["district"],
// //                         style: TextStyle(
// //                           fontSize: 10,
// //                           color: Colors.grey.shade600,
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                         maxLines: 1,
// //                       ),
// //                     ],
            
            
// //                   ),
// //                 ),
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
// //                   decoration: BoxDecoration(
// //                     color: Colors.green.withOpacity(0.1),
// //                     borderRadius: BorderRadius.circular(6),
// //                   ),
// //                   child: Row(
// //                     mainAxisSize: MainAxisSize.min,
// //                     children: [
// //                       Icon(Icons.star, color: Colors.amber, size: 12),
// //                       const SizedBox(width: 2),
// //                       Text(
// //                         branch["performance"].toString(),
// //                         style: const TextStyle(
// //                           fontSize: 11,
// //                           fontWeight: FontWeight.bold,
// //                           color: Colors.green,
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 5),

// //             // Manager
// //             Text(
// //               "Manager: ${branch["manager"]}",
// //               style: TextStyle(
// //                 fontSize: 10,
// //                 color: Colors.grey.shade600,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //               overflow: TextOverflow.ellipsis,
// //               maxLines: 1,
// //             ),
// //             const SizedBox(height: 7),

            

// //             // Address
// //             Row(
// //               children: [
// //                 Icon(Icons.location_on, size: 10, color: Colors.grey.shade500),
// //                 const SizedBox(width: 4),
// //                 Expanded(
// //                   child: Text(
// //                     branch["address"],
// //                     style: TextStyle(
// //                       fontSize: 9,
// //                       color: Colors.grey.shade500,
// //                     ),
// //                     overflow: TextOverflow.ellipsis,
// //                     maxLines: 1,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }



// //   String _getShortBranchName(String fullName) {
// //     return fullName.replaceAll(' Branch', '');
// //   }

// //   Widget _buildFilters() {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.shade300,
// //             blurRadius: 4,
// //             offset: const Offset(0, 1),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   "Branch",
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: Colors.grey.shade600,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(horizontal: 12),
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey.shade50,
// //                     borderRadius: BorderRadius.circular(8),
// //                     border: Border.all(color: Colors.grey.shade300),
// //                   ),
// //                   child: DropdownButtonHideUnderline(
// //                     child: DropdownButton<String>(
// //                       isExpanded: true,
// //                       value: _selectedBranch,
// //                       items: _branchNames.map((branch) {
// //                         return DropdownMenuItem<String>(
// //                           value: branch,
// //                           child: Text(
// //                             branch,
// //                             style: const TextStyle(fontSize: 14),
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                         );
// //                       }).toList(),
// //                       onChanged: (value) {
// //                         setState(() {
// //                           _selectedBranch = value!;
// //                         });
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   "Department",
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: Colors.grey.shade600,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(horizontal: 12),
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey.shade50,
// //                     borderRadius: BorderRadius.circular(8),
// //                     border: Border.all(color: Colors.grey.shade300),
// //                   ),
// //                   child: DropdownButtonHideUnderline(
// //                     child: DropdownButton<String>(
// //                       isExpanded: true,
// //                       value: _selectedDepartment,
// //                       items: _departments.map((dept) {
// //                         return DropdownMenuItem<String>(
// //                           value: dept,
// //                           child: Text(
// //                             dept,
// //                             style: const TextStyle(fontSize: 14),
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                         );
// //                       }).toList(),
// //                       onChanged: (value) {
// //                         setState(() {
// //                           _selectedDepartment = value!;
// //                         });
// //                       },
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildEmployeesList() {
// //     return Container(
// //       width: double.infinity,
// //       padding: const EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.shade300,
// //             blurRadius: 8,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Text(
// //                 "Employees (${_filteredEmployees.length})",
// //                 style: const TextStyle(
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               TextButton(
// //                 onPressed: () {},
// //                 style: TextButton.styleFrom(
// //                   padding: EdgeInsets.zero,
// //                   minimumSize: Size.zero,
// //                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //                 ),
// //                 child: const Text(
// //                   "View All",
// //                   style: TextStyle(
// //                     color: Colors.blue,
// //                     fontSize: 12,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 12),
// //           ..._filteredEmployees.map((employee) => _employeeItem(employee)),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _employeeItem(Map<String, dynamic> employee) {
// //     return Container(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       padding: const EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.grey.shade50,
// //         borderRadius: BorderRadius.circular(8),
// //         border: Border.all(color: Colors.grey.shade200),
// //       ),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Container(
// //             width: 36,
// //             height: 36,
// //             decoration: BoxDecoration(
// //               color: Colors.blue.withOpacity(0.1),
// //               shape: BoxShape.circle,
// //             ),
// //             child: Icon(
// //               Icons.person,
// //               color: Colors.blue,
// //               size: 18,
// //             ),
// //           ),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   employee["name"],
// //                   style: const TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 14,
// //                   ),
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 const SizedBox(height: 2),
// //                 Text(
// //                   "${employee["position"]} • ${employee["department"]}",
// //                   style: TextStyle(
// //                     fontSize: 11,
// //                     color: Colors.grey.shade600,
// //                   ),
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //                 Text(
// //                   "${employee["branch"]} • ${employee["district"]}",
// //                   style: TextStyle(
// //                     fontSize: 10,
// //                     color: Colors.grey.shade500,
// //                   ),
// //                   overflow: TextOverflow.ellipsis,
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(width: 8),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: [
// //               Row(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   Icon(Icons.star, color: Colors.amber, size: 12),
// //                   const SizedBox(width: 2),
// //                   Text(
// //                     employee["performance"].toString(),
// //                     style: const TextStyle(
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 "₹${(employee["salary"] / 1000).toStringAsFixed(0)}K",
// //                 style: TextStyle(
// //                   fontSize: 11,
// //                   color: Colors.green.shade600,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //               const SizedBox(height: 4),
// //               Container(
// //                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                 decoration: BoxDecoration(
// //                   color: Colors.green.withOpacity(0.1),
// //                   borderRadius: BorderRadius.circular(4),
// //                 ),
// //                 child: Text(
// //                   employee["status"],
// //                   style: TextStyle(
// //                     fontSize: 9,
// //                     color: Colors.green,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }