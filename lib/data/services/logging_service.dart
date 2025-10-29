import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';


// class LoggerReprository {
  
//   String name;
//   final Map<Level, String> defaultLevelColors = {
//     Level.FINEST: '\x1B[34m', // Blue
//     Level.INFO: '\x1B[32m', // Green
//     Level.WARNING: '\x1B[33m', // Yellow
//     Level.SEVERE: '\x1B[31m', // Red
//     Level.SHOUT: '\x1B[91m', // Bright Red
//   };

//   final Map<Level, String> defaultLevelEmojis = {
//     Level.FINEST: '',
//     //Level.debug: '🐛',
//     Level.INFO: '💡',
//     Level.WARNING: '⚠️',
//     Level.SEVERE: '⛔',
//     Level.SHOUT: '👾',
//   };
  
//   LoggerReprository(this.name){
//     _setupLogging();
//     // Logger.root.level = Level.ALL;
//     // _logger.onRecord.listen((LogRecord rec) {
//     //   final color = defaultLevelColors[rec.level];
//     //   final formattedMessage = '$color${rec.level.name}: ${rec.time}: [${rec.loggerName}] ${rec.message}\x1B[0m'; // Reset color
//     //   debugPrint(formattedMessage);
//     // });
//   }

//   late final Logger _logger = Logger(name);
//   ///Summery
//   ///
//   ///setup loggin
//   void _setupLogging() {
//     hierarchicalLoggingEnabled = true;
//     _logger.level = Level.ALL;
//     _logger.onRecord.listen((LogRecord rec) {
//       final color = defaultLevelColors[rec.level];
//       final formattedMessage = '$color${rec.level.name}: ${rec.time}: [${rec.loggerName}] ${rec.message}\x1B[0m';
//       print(formattedMessage); 
//     });
//   }
//   ///Summery
//   ///
//   ///log with info 
//   void i(dynamic message,{String? overrideName}){
//     overrideName ==null? 
//     _logger.info('$name: $message') : 
//     _logger.info('$overrideName: $message');
//   }
//   ///Summery
//   ///
//   ///log with severe 
//   void e(dynamic message,{String? overrideName,DateTime? time,Object? error,StackTrace? stackTrace}){
//     overrideName ==null?
//     _logger.severe('$name: $message',error,stackTrace):
//     _logger.severe('$overrideName: $message',error,stackTrace);
//   }
//   ///Summery
//   ///
//   ///log with shout 
//   void s(dynamic message,{String? overrideName,DateTime? time,Object? error,StackTrace? stackTrace}){
//     overrideName ==null?
//     _logger.shout('$name: $message',error,stackTrace):
//     _logger.shout('$overrideName: $message',error,stackTrace);
//   }
  
//   String _getColorForLevel(Level level) {
//     switch (level) {
//       case Level.SHOUT:
//         return '\x1B[91m'; // Bright Red
//       case Level.SEVERE:
//         return '\x1B[31m'; // Red
//       case Level.WARNING:
//         return '\x1B[33m'; // Yellow
//       case Level.INFO:
//         return '\x1B[32m'; // Green
//       case Level.CONFIG:
//       case Level.FINE:
//       case Level.FINER:
//       case Level.FINEST:
//         return '\x1B[34m'; // Blue
//       case Level.ALL:
//       case Level.OFF:
//       default:
//         return ''; // No color
//     }
//   }


// }

class LoggerReprository{
  
  LoggerReprository(this.name,{this.logView, this.logOutputMedia, this.filter}){
    switch (logView){
      case LogView.defaultView:
      
      _printer = SimpleLogPrinter(name??'log');
      
      // _printer = CustomPrettyOldPrinter(
      //   methodCount: 0,
      //   callerClass: name,
      // );
      
      // _printer = CustomPrettyPrinter(
      // methodCount: 1, // Number of method calls to be displayed
      // errorMethodCount: 8, // Number of method calls if stacktrace is provided
      // lineLength: 120, // Width of the output
      // colors: true, // Colorful log messages
      // printEmojis: true, // Print an emoji for each log message
      // printTime: false, // Should each log print contain a timestamp,
      // noBoxingByDefault: true
      // );
      break;
      case LogView.basic:
      _printer = CustomPrinter();
      break;
      case LogView.colorful:
      _printer = CustomColorfulPrinter();
      break;
      
      default:
      _printer = SimpleLogPrinter(name??'log');
      break;
    }
    switch (logOutputMedia){
      case LogOutputMedia.console:
      _logOutput = null;
      break;
      case LogOutputMedia.file:
      _logOutput = LoggerFileOutput();
      break;
      case LogOutputMedia.consolAndFile:
      _logOutput = LoggerConsolFileOutput();
      break;
      default:
      _logOutput = null;
      break;
    }
    log = Logger(
    filter: null, // Use the default LogFilter (only logs in debug mode)
    printer: _printer, // Use the PrettyPrinter to format and print log output
    output: _logOutput, // Use the default LogOutput (send everything to console)
    );
  }
  final LogFilter? filter;
  late LogPrinter? _printer;
  late LogOutput? _logOutput;
  late Logger log;
  final LogView? logView;
  final LogOutputMedia? logOutputMedia;
  String? name;
  
  void i(dynamic message,{String? overrideName}){
    overrideName ==null? log.i('$name: $message') : log.i('$overrideName: $message');
  }
  
  void e(dynamic message,{String? overrideName,DateTime? time,Object? error,StackTrace? stackTrace}){
    overrideName ==null?
    log.e('$name: $message',time: time,error: error,stackTrace: stackTrace):
    log.e('$overrideName: $message',time: time,error: error,stackTrace: stackTrace);
  }
  
  void l(Level level,dynamic message,{String? overrideName,DateTime? time,Object? error,StackTrace? stackTrace}){
    overrideName ==null?
    log.log(level,'$name: $message',time: time,error: error,stackTrace: stackTrace):
    log.log(level,'$overrideName: $message',time: time,error: error,stackTrace: stackTrace);
  }
}

class SimpleLogPrinter extends LogPrinter {
  final String name;
  SimpleLogPrinter(this.name);

  @override
  List<String> log(LogEvent event) {
    final level = event.level;
    final message = event.message;
    final time = _formatDateTime(DateTime.now());

    String color;
    String emoji;
    switch (level) {
      case Level.verbose:
        color = AnsiColors.white;
        emoji = '🔍';
        break;
      case Level.debug:
        color = AnsiColors.blue;
        emoji = '🐛';
        break;
      case Level.info:
        color = AnsiColors.green;
        emoji = '💡';
        break;
      case Level.warning:
        color = AnsiColors.yellow;
        emoji = '⚠️';
        break;
      case Level.error:
        color = AnsiColors.red;
        emoji = '❌';
        break;
      case Level.fatal:
        color = AnsiColors.magenta;
        emoji = '🚨';
        break;
      default:
        color = AnsiColors.cyan;
        emoji = '💡';
    }
    final stackTrace = StackTrace.current.toString();
    return [' ${color}$emoji $message${AnsiColors.reset}']; // [$time] after color
  }
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    
    return '$year-$month-$day $hour:$minute:$second';
  }
}

class AnsiColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
}

class CustomPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // Customize the log output based on the event
    final message = event.message;
    final level = event.level;

    // Example: Print log messages with a timestamp
    final timestamp = DateTime.now().toLocal().toString();
    final formattedMessage = '$timestamp [$level]: $message';

    return [formattedMessage];
  }
}

class CustomColorfulPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final message = event.message;
    final level = event.level;

    // Define ANSI escape codes for different log levels
    final color = {
      Level.trace: '\x1B[2m', // Dim
      Level.debug: '\x1B[34m', // Blue
      Level.info: '\x1B[32m', // Green
      Level.warning: '\x1B[33m', // Yellow
      Level.error: '\x1B[31m', // Red
    }[level] ?? '';

    final formattedMessage = '$color[$level] $message\x1B[0m'; // Reset color

    // Return the formatted message as a list
    return [formattedMessage];
  }
  
  static final Map<Level, AnsiColor> defaultLevelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  static final Map<Level, String> defaultLevelEmojis = {
    Level.trace: '',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.fatal: '👾',
  };
}
// class CustomPrettyPrinter extends LogPrinter {

  final Map<Level, AnsiColor> defaultLevelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  final Map<Level, String> defaultLevelEmojis = {
    Level.trace: '',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.fatal: '👾',
  };

class LoggerFileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (kDebugMode) {
        print(line);
      }
    }
  }
}

class LoggerConsolFileOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (kDebugMode) {
        print(line);
      }
    }
  }
}

enum LogView{
  defaultView,
  basic,
  colorful,
}

enum LogOutputMedia{
  console,
  file,
  consolAndFile
}