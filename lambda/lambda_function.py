import json, os, boto3

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime")

BUCKET = os.environ["FAQ_BUCKET"]
KEY = os.environ.get("FAQ_KEY", "faq.md")
MODEL_ID = os.environ["MODEL_ID"]
GUARDRAIL_ID = os.environ["GUARDRAIL_ID"]
GUARDRAIL_VERSION = os.environ["GUARDRAIL_VERSION"]

SYSTEM = """You are AfriKilo's support assistant.
Answer ONLY using the AfriKilo FAQ provided in the user's message.
If the answer is not in the FAQ, say you don't know and suggest contacting AfriKilo support at support@afrikilo.com.
Do not add advice, reasons or recommendations that are not in the FAQ.
Always reply in the language of the user's question (French or English), never both.
Keep answers short and friendly."""

LANGUAGE_RULE = """LANGUAGE RULE: The FAQ contains each answer in both French and English.
Reply ONLY in the language of the user's question: French question -> French answer only,
English question -> English answer only. Never include both languages. Do not add "FR:" or "EN:" labels."""

# Repeated after the question: without it, English questions that are not in
# the FAQ got French refusals.
LANGUAGE_REMINDER = """Reply in the same language as the question above, even if the answer is not in the FAQ. Do not add "FR:" or "EN:" labels."""

_faq = None
def get_faq():
    global _faq  # cached between invocations to avoid re-reading S3
    if _faq is None:
        obj = s3.get_object(Bucket=BUCKET, Key=KEY)
        _faq = obj["Body"].read().decode("utf-8")
    return _faq

def lambda_handler(event, context):
    body = event.get("body")
    if isinstance(body, str):
        body = json.loads(body or "{}")
    question = (body or event).get("question", "").strip()
    if not question:
        return {"statusCode": 400,
                "body": json.dumps({"error": "question is required"})}

    # guardContent tells the guardrail which text is the FAQ (grounding_source)
    # and which is the user's question (query). The question also needs
    # guard_content, otherwise input filters (prompt attack, denied topics)
    # skip it. Plain text blocks are instructions for the model only.
    resp = bedrock.converse(
        modelId=MODEL_ID,
        system=[{"text": SYSTEM}],
        messages=[{"role": "user", "content": [
            {"guardContent": {"text": {"text": get_faq(), "qualifiers": ["grounding_source"]}}},
            {"text": LANGUAGE_RULE + "\n\nUser question:"},
            {"guardContent": {"text": {"text": question, "qualifiers": ["query", "guard_content"]}}},
            {"text": LANGUAGE_REMINDER},
        ]}],
        inferenceConfig={"maxTokens": 400, "temperature": 0.2},
        guardrailConfig={
            "guardrailIdentifier": GUARDRAIL_ID,
            "guardrailVersion": GUARDRAIL_VERSION,
            "trace": "enabled",
        },
    )
    blocked = resp["stopReason"] == "guardrail_intervened"
    if blocked:
        print(json.dumps({"guardrail_trace": resp.get("trace", {}).get("guardrail")}))
    answer = resp["output"]["message"]["content"][0]["text"]
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"answer": answer, "blocked": blocked, "usage": resp["usage"]},
                           ensure_ascii=False),
    }
