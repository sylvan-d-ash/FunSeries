//
//  Logger.swift
//  Topcoder-FunSeries-SurveyApp
//
//  Created by Sylvan .D. Ash on 2/1/16.
//  Copyright © 2016 topcoder. All rights reserved.
//

import Foundation

/// Class used for logging messages
public class Logger: NSObject {
    
    var logLevel: LogLevel = .Error
    
    /**
     Type describing log levels
     
     - Debug:   Debug log level
     - Info:    Info log level
     - Warning: Warning log level
     - Error:   Error log level
     */
    public enum LogLevel: Int {
        case Debug   = 1
        case Info    = 2
        case Warning = 3
        case Error   = 4
        
        /**
         Return string representation of log level

         - returns: String representation of log level
         */
        func toString() -> String {
            switch self {
            case .Debug:
                return "Debug"
            case .Info:
                return "Info"
            case .Warning:
                return "Warning"
            case .Error:
                return "Error"
            }
        }
    }
    
    /// Singleton instance used to write logs in class methods
    static let instance = Logger()
    
    /**
     Default initializer. Updates log level with value from configuration file if available
     
     - returns initialized object
     */
    override init() {
        super.init()
        
        if let configPath = NSBundle.mainBundle().pathForResource("config", ofType: "plist"),
            let config = NSDictionary(contentsOfFile: configPath) as? Dictionary<String, AnyObject> {
            if let logLevel = config["LogLevel"] as? String {
                switch logLevel {
                case "Debug":   self.logLevel = .Debug
                case "Info":    self.logLevel = .Info
                case "Warning": self.logLevel = .Warning
                case "Error":   self.logLevel = .Error
                default: break
                }
            }
        } else {
            //Logger.errorFrom(self, message: "Could not read config.plist file. This is a serious error!")
            print("error opening file")
        }
    }
    
    /**
     Log message.
     
     - parameter object:   object logged as author of this message
     - parameter message:  message to write
     - parameter logLevel: log level of this message
     */
    public func logFrom(object: AnyObject, message: String, logLevel: LogLevel) {
        if logLevel.rawValue >= self.logLevel.rawValue {
            print("[\(NSDate().timeIntervalSince1970)][\(object.dynamicType)] \(logLevel.toString()): \(message)")
        }
    }
    
    /** 
     Log info level messages
     
     - parameter object:  object logged as author of this message
     - parameter message: message to write
     */
    public class func infoFrom(object: AnyObject, message: String) {
        Logger.instance.logFrom(object, message: message, logLevel: .Info)
    }
    
    /** 
     Log debug level messages
     
     - parameter object:  object logged as author of this message
     - parameter message: message to write
     */
    public class func debugFrom(object: AnyObject, message: String) {
        Logger.instance.logFrom(object, message: message, logLevel: .Debug)
    }
    
    /**
     Log warning level messages
     
     - parameter object:  object logged as author of this message
     - parameter message: message to write
     */
    public class func warningFrom(object: AnyObject, message: String) {
        Logger.instance.logFrom(object, message: message, logLevel: .Warning)
    }
    
    /** 
     Log error level messages
     
     - parameter object:  object logged as author of this message
     - patameter message: message to write
     */
    public class func errorFrom(object: AnyObject, message: String) {
        Logger.instance.logFrom(object, message: message, logLevel: .Error)
    }
    
    /** 
     Method used to log function calls
     
     - parameter caller:    object logged as author of this message
     - parameter arguments: array of function arguments
     - parameter function:  funciton name (filled in automatically)
     */
    public class func logFunction(caller: AnyObject, arguments: [Any] = [], function: String = __FUNCTION__) {
        Logger.instance.logFrom(caller, message: "\(function) \(arguments)", logLevel: .Info)
    }
}