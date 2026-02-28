import aiohttp
import json
import asyncio
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class DeepSeekSmartReplyAdapter:
    def __init__(self):
        self.api_key = settings.AI_PROVIDERS['deepseek'].get('api_key', '')
        self.api_url = "https://api.deepseek.com/v1/chat/completions"
        
    async def generate_suggestions(self, conversation_history, max_suggestions=3):
        if not self.api_key:
            logger.warning("No DeepSeek API key, using fallback")
            return self._get_fallback_suggestions()
        
        prompt = self._build_prompt(conversation_history, max_suggestions)
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    self.api_url,
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": "deepseek-chat",
                        "messages": [
                            {
                                "role": "system", 
                                "content": "You are a smart reply generator. Generate short, natural reply options."
                            },
                            {
                                "role": "user",
                                "content": prompt
                            }
                        ],
                        "temperature": 0.3,
                        "max_tokens": 150
                    },
                    timeout=5
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return self._parse_suggestions(result)
                    else:
                        return self._get_fallback_suggestions()
                        
        except Exception as e:
            logger.error(f"Error calling DeepSeek API: {e}")
            return self._get_fallback_suggestions()
    
    def _build_prompt(self, history, max_suggestions):
        recent = history[-6:] if len(history) > 6 else history
        history_text = "\n".join(recent)
        
        return f"""Based on this conversation:
{history_text}

Generate {max_suggestions} short, natural reply options.
Each reply should be under 60 characters.
Return ONLY a JSON array of strings.
Example: ["Thanks!", "Sounds good", "I'll check"]"""
    
    def _parse_suggestions(self, response):
        try:
            content = response['choices'][0]['message']['content']
            
            import re
            json_match = re.search(r'\[.*\]', content, re.DOTALL)
            if json_match:
                suggestions = json.loads(json_match.group())
                if isinstance(suggestions, list):
                    return [s.strip()[:60] for s in suggestions if s][:3]
        except:
            pass
        return self._get_fallback_suggestions()
    
    def _get_fallback_suggestions(self):
        from django.conf import settings
        return settings.SMART_REPLY['FALLBACK_SUGGESTIONS']
