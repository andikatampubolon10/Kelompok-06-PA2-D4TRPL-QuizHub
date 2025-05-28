import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
   ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFF6200EE),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF6200EE),
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Mentions'),
                  Tab(text: 'Updates'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildActivityList(context, _allActivities),
                    _buildActivityList(context, _mentionActivities),
                    _buildActivityList(context, _updateActivities),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, List<Map<String, dynamic>> activities) {
    return activities.isEmpty
        ? const Center(
            child: Text(
              'No activities yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityItem(
                context,
                activity['avatar']!,
                activity['name']!,
                activity['action']!,
                activity['time']!,
                activity['isRead']! as bool,
              );
            },
          );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String avatar,
    String name,
    String action,
    String time,
    bool isRead,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0E5FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(avatar),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' $action',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF6200EE),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Sample activity data
  final List<Map<String, dynamic>> _allActivities = [
    {
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'name': 'John Doe',
      'action': 'commented on your post',
      'time': '2 minutes ago',
      'isRead': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'name': 'Jane Smith',
      'action': 'liked your comment',
      'time': '15 minutes ago',
      'isRead': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'name': 'Robert Johnson',
      'action': 'shared your post',
      'time': '1 hour ago',
      'isRead': true,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'name': 'Emily Davis',
      'action': 'mentioned you in a comment',
      'time': '3 hours ago',
      'isRead': true,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'name': 'Michael Wilson',
      'action': 'started following you',
      'time': '1 day ago',
      'isRead': true,
    },
  ];

  final List<Map<String, dynamic>> _mentionActivities = [
    {
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'name': 'Emily Davis',
      'action': 'mentioned you in a comment',
      'time': '3 hours ago',
      'isRead': true,
    },
  ];

  final List<Map<String, dynamic>> _updateActivities = [
    {
      'avatar': 'https://i.pravatar.cc/150?img=6',
      'name': 'System',
      'action': 'New features available in the app',
      'time': '1 day ago',
      'isRead': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'name': 'System',
      'action': 'Your account was successfully verified',
      'time': '3 days ago',
      'isRead': true,
    },
  ];
}
