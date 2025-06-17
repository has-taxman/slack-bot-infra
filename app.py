from dotenv import load_dotenv
import os
import json
import requests
import random
import hmac
import hashlib
from flask import Flask, request, Response

# Load environment variables
load_dotenv()

SLACK_BOT_TOKEN = os.getenv("SLACK_BOT_TOKEN")
SLACK_SIGNING_SECRET = os.getenv("SLACK_SIGNING_SECRET")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL")

app = Flask(__name__)

# Health check endpoint for ALB
@app.route("/health", methods=["GET"])
def health_check():
    return "OK", 200

# Main Slack events endpoint
@app.route("/slack/events", methods=["POST"])
def slack_events():
    data = request.get_json()
    app.logger.debug(f"Received Slack payload: {data}")

    # 1) Handle URL verification challenge first (no signature required)
    if data and data.get("type") == "url_verification":
        challenge = data.get("challenge")
        return Response(challenge, mimetype="text/plain", status=200)

    # 2) Extract Slack signature headers
    timestamp = request.headers.get("X-Slack-Request-Timestamp")
    signature = request.headers.get("X-Slack-Signature")

    # 3) Verify request signature
    if not verify_slack_signature(request.get_data(), timestamp, signature):
        app.logger.warning("Invalid Slack signature.")
        return Response("Invalid signature", status=403)

    # 4) Handle event callbacks
    if data.get("type") == "event_callback":
        event = data.get("event", {})
        if event.get("type") == "message" and not event.get("subtype"):
            respond_to_message(event)

    return Response(status=200)


def verify_slack_signature(request_data, timestamp, signature):
    """
    Verify incoming Slack request using signing secret
    """
    if not timestamp or not signature:
        return False
    basestring = f"v0:{timestamp}:{request_data.decode('utf-8')}"
    computed = hmac.new(
        SLACK_SIGNING_SECRET.encode('utf-8'),
        basestring.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"v0={computed}", signature)


def send_slack_message(channel, text):
    payload = {"channel": channel, "text": text}
    headers = {'Content-Type': 'application/json'}
    resp = requests.post(SLACK_WEBHOOK_URL, json=payload, headers=headers)
    if resp.status_code != 200:
        app.logger.error(f"Slack message failed: {resp.status_code} {resp.text}")


def respond_to_message(event):
    text = event.get("text", "").lower()
    user = event.get("user")
    channel = event.get("channel")

    if "hello" in text or "hi" in text:
        send_slack_message(channel, f"Hello <@{user}>! How can I help you today?")
    elif "help" in text:
        send_slack_message(channel, (
            "I can say hello or tell you a joke! Just say 'hello', 'hi', or 'tell me a joke'."
        ))
    elif "tell me a joke" in text:
        joke = random.choice([
            "Why don't scientists trust atoms? Because they make up everything!",
            "What do you call a lazy kangaroo? Pouch potato!",
            "Why did the bicycle fall over? Because it was two tired!",
            "Knock, knock. Lettuce. Lettuce who? Lettuce in! It's cold out here!",
            "What musical instrument is found in the bathroom? A tuba toothpaste."
        ])
        send_slack_message(channel, joke)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8080)
