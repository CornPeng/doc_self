import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<SearchResult> _searchResults = [
    SearchResult(
      author: 'You',
      time: '10:45 AM',
      content: 'Found a great #Idea for the new UI layout while walking. Needs more Search functionality improvements.',
      tags: ['#Idea', 'UI', 'Search'],
      syncStatus: 'Synced via Bluetooth',
    ),
    SearchResult(
      author: 'iPad Sync',
      time: 'Yesterday',
      content: 'Updated the #Work documentation for the UI design kit. Added 4 new components.',
      tags: ['#Work', 'UI'],
      syncStatus: 'P2P Synced',
      hasImage: true,
    ),
    SearchResult(
      author: 'You',
      time: 'Aug 12',
      content: 'Shared a link to the UI inspiration board. Most items are #Private for now.',
      tags: ['link', 'UI', '#Private'],
      syncStatus: 'Synced via Bluetooth',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            color: const Color(0xFF137FEC),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Search',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.bluetooth_connected,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF137FEC),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF283039).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search your local notes...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Results Section
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ENCRYPTED VAULT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._searchResults.map((result) => _buildResultCard(result)),
                ],
              ),
            ),
            
            // Bottom Badge
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:               Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Colors.grey.shade900,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Local Encrypted Search',
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A242F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: result.author == 'You'
                          ? const Color(0xFF137FEC).withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      result.author == 'You' ? Icons.person : Icons.devices,
                      color: result.author == 'You'
                          ? const Color(0xFF137FEC)
                          : Colors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.author,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                result.time.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Content with highlighted tags
          _buildHighlightedText(result.content, result.tags),
          
          // Image placeholder if has image
          if (result.hasImage) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF283039),
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF137FEC).withOpacity(0.2),
                    Colors.purple.withOpacity(0.2),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: Colors.white.withOpacity(0.4),
                  size: 32,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Sync status
          Row(
            children: [
              Icon(
                Icons.done_all,
                color: const Color(0xFF137FEC),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                result.syncStatus,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, List<String> tags) {
    final spans = <TextSpan>[];
    var remainingText = text;
    
    for (final tag in tags) {
      final parts = remainingText.split(tag);
      if (parts.length > 1) {
        spans.add(TextSpan(text: parts[0]));
        spans.add(
          TextSpan(
            text: tag,
            style: const TextStyle(
              backgroundColor: Color(0x33137FEC),
              color: Color(0xFF137FEC),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        remainingText = parts.sublist(1).join(tag);
      }
    }
    
    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(text: remainingText));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
          height: 1.5,
        ),
        children: spans.isEmpty
            ? [TextSpan(text: text)]
            : spans,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class SearchResult {
  final String author;
  final String time;
  final String content;
  final List<String> tags;
  final String syncStatus;
  final bool hasImage;

  SearchResult({
    required this.author,
    required this.time,
    required this.content,
    required this.tags,
    required this.syncStatus,
    this.hasImage = false,
  });
}
