locals {
  blocked_message = "Désolé, je ne peux pas répondre à cette demande. Contactez support@afrikilo.com. / Sorry, I can't help with that. Please contact support@afrikilo.com."
}

resource "aws_bedrock_guardrail" "this" {
  name                      = "${var.project_name}-guardrail"
  description               = "AfriKilo support assistant: block attacks, harmful content, customs evasion and ungrounded answers."
  blocked_input_messaging   = local.blocked_message
  blocked_outputs_messaging = local.blocked_message

  content_policy_config {
    dynamic "filters_config" {
      for_each = ["HATE", "INSULTS", "SEXUAL", "VIOLENCE", "MISCONDUCT"]
      content {
        type            = filters_config.value
        input_strength  = "HIGH"
        output_strength = "HIGH"
      }
    }

    # Prompt attacks only apply to user input.
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
  }

  # No denied topic for customs evasion: in testing, the MISCONDUCT filter
  # already blocked those questions on input (EN and FR), while a "Customs
  # evasion" topic also fired on the OUTPUT and blocked the normal FAQ answer
  # listing prohibited items. The Terraform provider can't limit a topic to
  # input only, so the topic was removed. See docs/test-results.md.

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  contextual_grounding_policy_config {
    filters_config {
      type      = "GROUNDING"
      threshold = var.grounding_threshold
    }
  }
}

# The Lambda points to a fixed version, never the working draft.
resource "aws_bedrock_guardrail_version" "this" {
  guardrail_arn = aws_bedrock_guardrail.this.guardrail_arn
  description   = "Managed by Terraform"

  lifecycle {
    replace_triggered_by = [aws_bedrock_guardrail.this]
  }
}
