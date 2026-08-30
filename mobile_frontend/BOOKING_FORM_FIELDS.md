The error is still coming from the backend — that message is the giveaway.

Why this is backend-side
"executor is not a function" is a JavaScript TypeError, not a validation error. It's the exact text V8 throws when code does new Promise(executor) where executor isn't a function. It's leaking into the 400 response via a generic error handler.

Critically, look at what your own API docs now say the 400 should be:

Your docs say 400 =	What you're actually getting
Session has no agreed amount or amount mismatch	executor is not a function
If the backend fix had actually landed, you'd either get a clean 201 with paystackAuthorizationUrl, or the documented 400 text. Getting executor is not a function means the /api/payments/initiate handler is still crashing before/inside its Paystack call — the fix isn't deployed, or only fixed one code path and this request hits another.

The one client-side thing the new docs changed
Your docs now say: "The amount is ALWAYS taken from the session's agreed amount — the amount field in the body is validated against it and never trusted."

Your booking flow was sending booking.packagePrice (the rate-card price), which may differ from the session's stored agreed_amount. I aligned it so the client now sends the session's actual agreed_amount from the createSession response, falling back to the package price. This is the correct behavior regardless, and it removes the amount-mismatch variable entirely.

For the retry path I added earlier, it already reads agreed_amount (via the model change), so both flows are now consistent.

To pinpoint the backend bug
Ask the backend dev to do these three things, in order:

Confirm the deploy actually took — hit POST /api/payments/initiate with Postman/curl using the exact body your app sends:


If Postman also gets executor is not a function, it's 100% server-side (no Flutter involved).

Get the stack trace, not the message. The API is swallowing it. Have them log err.stack in the initiate handler's catch block. The offending line will be the new Promise(...) / Paystack SDK call.

Look for the three classic culprits (from the original diagnosis):

const paystack = require('paystack')(key) returning something that isn't callable, then being invoked as a function.
A method that returns a value now being passed where a callback belongs (e.g. new Promise(amount) or transaction.initialize(data, amount) instead of (data, callback)).
An SDK version bump where a method switched from promise-returning to callback-style (or vice-versa).
If, after my amount alignment, Postman gets the documented 400 "amount mismatch" (not the executor error), then the amount fix matters and we're on the right track. But as long as the message is literally executor is not a function, the ball is in the backend's court.