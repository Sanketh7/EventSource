//
//  Event.swift
//  EventSource
//
//  Created by Andres on 01/06/2019.
//  Copyright © 2019 inaka. All rights reserved.
//

import Foundation

enum Event {
    case event(id: String?, event: String?, data: String?, time: String?)

    init?(eventString: String?, newLineCharacters: [String]) {
        guard let eventString = eventString else { return nil }

        if eventString.hasPrefix(":") {
            return nil
        }

        self = Event.parseEvent(eventString, newLineCharacters: newLineCharacters)
    }

    var id: String? {
        guard case let .event(eventId, _, _, _) = self else { return nil }
        return eventId
    }

    var event: String? {
        guard case let .event(_, eventName, _, _) = self else { return nil }
        return eventName
    }

    var data: String? {
        guard case let .event(_, _, eventData, _) = self else { return nil }
        return eventData
    }

    var retryTime: Int? {
        guard case let .event(_, _, _, aTime) = self, let time = aTime else { return nil }
        return Int(time.trimmingCharacters(in: CharacterSet.whitespaces))
    }

    var onlyRetryEvent: Bool? {
        guard case let .event(id, name, data, time) = self else { return nil }
        let otherThanTime = id ?? name ?? data

        if otherThanTime == nil && time != nil {
            return true
        }

        return false

    }
}

private extension Event {

    static func parseEvent(_ eventString: String, newLineCharacters: [String]) -> Event {
        var event: [String: String?] = [:]

        for line in eventString.components(separatedBy: CharacterSet.newlines) as [String] {
            let (akey, value) = Event.parseLine(line, newLineCharacters: newLineCharacters)
            guard let key = akey else { continue }

            if let value = value, let previousValue = event[key] ?? nil {
                event[key] = "\(previousValue)\n\(value)"
            } else if let value = value {
                event[key] = value
            } else {
                event[key] = nil
            }
        }

        // the only possible field names for events are: id, event and data. Everything else is ignored.
        return .event(
            id: event["id"] ?? nil,
            event: event["event"] ?? nil,
            data: event["data"] ?? nil,
            time: event["retry"] ?? nil
        )
    }

    static func parseLine(_ line: String, newLineCharacters: [String]) -> (key: String?, value: String?) {
        var key: String?, value: String?
        let scanner = Scanner(string: line)
        scanner.charactersToBeSkipped = .newlines
        if #available(iOS 13, *) {
            key = scanner.scanUpToString(":")
            _ = scanner.scanString(":")
            _ = scanner.scanString(" ")
        } else {
            var tmpKey: NSString?
            scanner.scanUpTo(":", into: &tmpKey)
            _ = scanner.scanString(":", into: nil)
            _ = scanner.scanString(" ", into: nil)
            key = tmpKey as String?
        }

        for newline in newLineCharacters {
            if #available(iOS 13, *) {
                value = scanner.scanUpToString(newline)
                if value != nil {
                    break
                }
            } else {
                var tmpValue: NSString?
                if scanner.scanUpTo(newline, into: &tmpValue) {
                    value = tmpValue as String?
                    break
                }
            }
        }

        // for id and data if they come empty they should return an empty string value.
        if key != "event" && value == nil {
            value = ""
        }

        return (key, value)
    }
}
