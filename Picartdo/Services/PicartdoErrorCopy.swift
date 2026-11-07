import Foundation
import AuthenticationServices

/// Turns raw errors into a sentence a person can act on: what happened, and what to
/// do now. Never "Something went wrong", never a status code or a server message.
enum PicartdoErrorCopy {

    /// - Parameter action: what the person was doing, phrased to follow "We couldn't",
    ///   e.g. "list your piece", "send your request".
    static func message(for error: Error, action: String) -> String {
        if let url = error as? URLError {
            switch url.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return "You\u{2019}re offline, so we couldn\u{2019}t \(action). Check your connection and try again."
            case .timedOut:
                return "Picartdo took too long to answer, so we couldn\u{2019}t \(action). Try again in a moment."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return "We couldn\u{2019}t reach Picartdo to \(action). Try again in a moment."
            default:
                break
            }
        }

        if let supabase = error as? SupabaseError {
            switch supabase {
            case .unauthorized:
                return "Your session has ended. Sign in again to \(action)."
            case .http(let code, _) where code == 401 || code == 403:
                return "Your session has ended. Sign in again to \(action)."
            case .http(let code, _) where code == 413:
                return "That photo is too large to upload. Try a smaller one."
            case .http(let code, _) where code == 429:
                return "Too many tries in a row. Wait a minute, then try again."
            case .http(let code, _) where code >= 500:
                return "Picartdo is having trouble right now, so we couldn\u{2019}t \(action). Try again in a few minutes."
            case .notConfigured:
                return "This build isn\u{2019}t connected to Picartdo\u{2019}s servers, so we couldn\u{2019}t \(action)."
            default:
                break
            }
        }

        if (error as NSError).domain == NSURLErrorDomain {
            return "There was a connection problem, so we couldn\u{2019}t \(action). Try again."
        }

        return "We couldn\u{2019}t \(action). Try again, and if it keeps happening, report it in Settings \u{203A} Report a problem."
    }

    /// Sign in with Apple: cancelling is a choice, not an error.
    static func signIn(_ error: Error) -> String? {
        if let auth = error as? ASAuthorizationError {
            switch auth.code {
            case .canceled: return nil
            case .notHandled, .failed:
                return "Apple couldn\u{2019}t complete sign-in. Try again."
            default: break
            }
        }
        return message(for: error, action: "sign you in")
    }
}
