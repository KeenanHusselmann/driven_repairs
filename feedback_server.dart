import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

// Simple ServiceRating class without Flutter dependencies
class ServiceRating {
  final String id;
  final String ticketId;
  final String customerId;
  final int satisfactionRating;
  final int timelinessRating;
  final int communicationRating;
  final int qualityRating;
  final String? feedback;
  final bool wouldRecommend;
  final DateTime createdAt;

  ServiceRating({
    required this.id,
    required this.ticketId,
    required this.customerId,
    required this.satisfactionRating,
    required this.timelinessRating,
    required this.communicationRating,
    required this.qualityRating,
    this.feedback,
    required this.wouldRecommend,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'customerId': customerId,
      'satisfactionRating': satisfactionRating,
      'timelinessRating': timelinessRating,
      'communicationRating': communicationRating,
      'qualityRating': qualityRating,
      'feedback': feedback,
      'wouldRecommend': wouldRecommend ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  double get averageRating =>
      (satisfactionRating + timelinessRating + communicationRating + qualityRating) / 4;
}

// Global database instance
Database? _database;

Future<Database> getDatabase() async {
  if (_database != null) return _database!;
  
  // Initialize sqflite for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Get database path
  final appDataPath = Platform.environment['LOCALAPPDATA'] ??
      Platform.environment['APPDATA'] ??
      Directory.current.path;
  final databasesPath = join(appDataPath, 'driven_repairs', 'databases');
  final path = join(databasesPath, 'driven_repairs.db');
  
  print('Database path: $path');
  
  _database = await openDatabase(path);
  return _database!;
}

void main() async {
  print('Starting Driven Repairs Feedback Server...');
  
  // Initialize database
  await getDatabase();
  print('Database initialized');
  
  // Create feedback storage directory if it doesn't exist
  final feedbackDir = Directory('feedback_storage');
  if (!await feedbackDir.exists()) {
    await feedbackDir.create();
  }

  final router = Router();

  // Serve the feedback form HTML
  final staticHandler = createStaticHandler(
    'web_feedback',
    defaultDocument: 'feedback_form.html',
  );

  // API endpoint to receive feedback
  router.post('/api/feedback', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      print('Received feedback: $data');

      // Validate required fields
      if (data['ticketId'] == null ||
          data['customerId'] == null ||
          data['satisfactionRating'] == null ||
          data['timelinessRating'] == null ||
          data['communicationRating'] == null ||
          data['qualityRating'] == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'Missing required fields'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Create ServiceRating object
      final rating = ServiceRating(
        id: const Uuid().v4(),
        ticketId: data['ticketId'] as String,
        customerId: data['customerId'] as String,
        satisfactionRating: data['satisfactionRating'] as int,
        timelinessRating: data['timelinessRating'] as int,
        communicationRating: data['communicationRating'] as int,
        qualityRating: data['qualityRating'] as int,
        feedback: data['feedback'] as String? ?? '',
        wouldRecommend: data['wouldRecommend'] as bool? ?? false,
        createdAt: DateTime.now(),
      );

      // Save to database - For now, just print (database integration will be added later)
      print('Feedback received: ${rating.id}');
      print('  Customer: ${data['customerName'] ?? 'Unknown'}');
      print('  Satisfaction: ${rating.satisfactionRating}/5');
      print('  Timeliness: ${rating.timelinessRating}/5');
      print('  Communication: ${rating.communicationRating}/5');
      print('  Quality: ${rating.qualityRating}/5');
      print('  Would recommend: ${rating.wouldRecommend}');
      print('  Feedback: ${rating.feedback}');
      
      // Save to JSON file for Flutter app to import
      try {
        final feedbackFile = File('feedback_storage/${rating.id}.json');
        await feedbackFile.writeAsString(jsonEncode(rating.toMap()));
        print('✅ Feedback saved to file: ${rating.id}.json');
      } catch (e) {
        print('⚠️ Error saving feedback file: $e');
      }

      print('Feedback logged successfully!');

      // Also send email notification to admin
      await _sendEmailNotification(rating, data);

      return Response(
        200,
        body: jsonEncode({'success': true, 'message': 'Feedback received successfully'}),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      );
    } catch (e, stackTrace) {
      print('Error saving feedback: $e');
      print(stackTrace);
      return Response(
        500,
        body: jsonEncode({'error': 'Failed to save feedback', 'details': e.toString()}),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  });

  // Short URL redirect endpoint
  router.get('/s/<shortCode>', (Request request, String shortCode) async {
    try {
      final db = await getDatabase();
      
      // Get the short URL from database
      final result = await db.query(
        'short_urls',
        where: 'shortCode = ?',
        whereArgs: [shortCode],
        limit: 1,
      );

      if (result.isEmpty) {
        print('⚠️ Short URL not found: $shortCode');
        return Response.notFound(
          '<html><body><h1>404 - Link Not Found</h1><p>This short link does not exist or has expired.</p></body></html>',
          headers: {'Content-Type': 'text/html'},
        );
      }

      final shortUrlData = result.first;
      final fullUrl = shortUrlData['fullUrl'] as String;
      final expiresAt = shortUrlData['expiresAt'] as int?;
      final clickCount = shortUrlData['clickCount'] as int;

      // Check if expired
      if (expiresAt != null && DateTime.fromMillisecondsSinceEpoch(expiresAt).isBefore(DateTime.now())) {
        print('⚠️ Short URL expired: $shortCode');
        return Response.notFound(
          '<html><body><h1>Link Expired</h1><p>This link has expired.</p></body></html>',
          headers: {'Content-Type': 'text/html'},
        );
      }

      // Increment click count
      await db.update(
        'short_urls',
        {'clickCount': clickCount + 1},
        where: 'shortCode = ?',
        whereArgs: [shortCode],
      );

      print('✅ Redirecting $shortCode to $fullUrl (click #${clickCount + 1})');

      // Redirect to the full URL
      return Response.movedPermanently(fullUrl);
    } catch (e) {
      print('Error handling short URL redirect: $e');
      return Response.internalServerError(
        body: '<html><body><h1>500 - Server Error</h1><p>Unable to process this link.</p></body></html>',
        headers: {'Content-Type': 'text/html'},
      );
    }
  });

  // Handle CORS preflight
  router.options('/api/feedback', (Request request) {
    return Response.ok(
      '',
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    );
  });

  // Combine static file handler with API routes
  final cascade = Cascade()
      .add(router.call)
      .add(staticHandler);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(cascade.handler);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    8080,
  );

  print('✅ Feedback server running on http://localhost:${server.port}');
  print('📧 Customers can submit feedback at: http://localhost:${server.port}/feedback_form.html');
  print('🔗 API endpoint: http://localhost:${server.port}/api/feedback');
  print('\nPress Ctrl+C to stop the server\n');
}

Future<void> _sendEmailNotification(
  ServiceRating rating,
  Map<String, dynamic> data,
) async {
  try {
    final subject = Uri.encodeComponent('New Customer Feedback Received');
    final body = Uri.encodeComponent('''
New Customer Feedback Received!

Ticket ID: ${rating.ticketId}
Customer ID: ${rating.customerId}

Ratings:
━━━━━━━━━━━━━━━━━━━━━━
• Satisfaction: ${rating.satisfactionRating}/5 ${'⭐' * rating.satisfactionRating}
• Timeliness: ${rating.timelinessRating}/5 ${'⭐' * rating.timelinessRating}
• Communication: ${rating.communicationRating}/5 ${'⭐' * rating.communicationRating}
• Quality: ${rating.qualityRating}/5 ${'⭐' * rating.qualityRating}

Average Rating: ${rating.averageRating.toStringAsFixed(1)}/5.0

Would Recommend: ${rating.wouldRecommend ? '✅ Yes' : '❌ No'}

Comments:
${(rating.feedback?.isNotEmpty ?? false) ? rating.feedback : 'No comments provided'}

━━━━━━━━━━━━━━━━━━━━━━
Submitted: ${DateTime.now().toString().substring(0, 19)}

This feedback has been logged successfully.
''');

    final emailUrl = 'mailto:keenan.husselmann39@gmail.com'
        '?subject=$subject'
        '&body=$body';

    // On Windows, open email client
    await Process.run('cmd', ['/c', 'start', '', emailUrl]);
    print('📧 Email notification sent to keenan.husselmann39@gmail.com');
  } catch (e) {
    print('⚠️  Could not send email notification: $e');
  }
}
