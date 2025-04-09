import os
import json
import requests
import random  # Import the random module
from flask import Flask, request, Response

SLACK_BOT_TOKEN = "VELJIQVuEHIKlXXlsf0tHbwD"
SLACK_SIGNING_SECRET = "a2b9987b83b72df999c4307d078af125"
SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/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"

app = Flask(__name__)

# A list of jokes for the bot to tell
jokes = [
    "Why don't scientists trust atoms? Because they make up everything!",
    "What do you call a lazy kangaroo? Pouch potato!",
    "Why did the bicycle fall over? Because it was two tired!",
    "Knock, knock. Who's there? Lettuce. Lettuce who? Lettuce in! It's cold out here!",
    "What musical instrument is found in the bathroom? A tuba toothpaste."
]



def respond_to_message(event):
    if "text" in event:
        user = event.get("user")
        text = event.get("text")
        channel = event.get("channel")

        if "hello" in text.lower() or "hi" in text.lower():
            response_text = f"Hello <@{user}>! How can I help you today?"
            send_slack_message(channel, response_text)
        elif "help" in text.lower():
            response_text = "I can say hello or tell you a joke! Just mention me or send me a direct message saying 'hello', 'hi', or 'tell me a joke'."
            send_slack_message(channel, response_text)
        elif "tell me a joke" in text.lower():
            joke = random.choice(jokes)  # Pick a random joke from the list
            response_text = joke
            send_slack_message(channel, response_text)

def send_slack_message(channel, text):
    webhook_url = SLACK_WEBHOOK_URL  # Use the global variable # Alternatively, use the Bot Token for more control
    payload = {
        "channel": channel,
        "text": text
    }
    headers = {
        'Content-Type': 'application/json'
    }
    response = requests.post(webhook_url, data=json.dumps(payload), headers=headers)
    if response.status_code != 200:
        print(f"Error sending message: {response.status_code} - {response.text}")

def verify_slack_signature(request_data, timestamp, signature):
    """
    Verifies the signature of the incoming Slack request.
    """
    signing_secret = SLACK_SIGNING_SECRET
    basestring = f"v0:{timestamp}:{request_data.decode('utf-8')}"
    my_signature = hmac.new(signing_secret.encode('utf-8'), basestring.encode('utf-8'), hashlib.sha256).hexdigest()
    return hmac.compare_digest(f"v0={my_signature}", signature)

@app.route("/slack/events", methods=["POST"])
def slack_events():
    print("Received a POST request to /slack/events")

    if not SLACK_SIGNING_SECRET:
        print("SLACK_SIGNING_SECRET not configured.")
        return Response("Slack Signing Secret not configured", status=500)

    request_data = request.get_data()
    timestamp = request.headers.get("X-Slack-Request-Timestamp")
    signature = request.headers.get("X-Slack-Signature")

    print(f"Timestamp: {timestamp}")
    print(f"Signature: {signature}")
    print(f"Request Data: {request_data.decode('utf-8')}")

    if not verify_slack_signature(request_data, timestamp, signature):
        print("Invalid Slack signature.")
        return Response("Invalid Slack signature", status=403)
    else:
        print("Slack signature verified successfully.")

    data = request.get_json()
    print(f"Parsed JSON data: {data}")

    if data and "type" in data and data["type"] == "url_verification":
        print("Handling url_verification request.")
        challenge_value = data.get("challenge")
        print(f"Challenge value: {challenge_value}")
        return Response(challenge_value, mimetype="text/plain", status=200)
    elif data and "type" in data and data["type"] == "event_callback":
        print("Handling event_callback request.")
        event = data["event"]
        if event.get("type") == "message" and not event.get("subtype"):
            respond_to_message(event)
    else:
        print("Received an unexpected type of request.")

    return Response(status=200)
@app.route("/health", methods=["GET"])
def health_check():
    return "OK", 200

if __name__ == "__main__":
    import hmac
    import hashlib
    app.run(debug=True, host='0.0.0.0', port=8080)

