import os
import requests
from dotenv import load_dotenv

load_dotenv()

def test_deepseek_api():
    api_key = os.getenv('DEEPSEEK_API_KEY')
    if not api_key:
        print("âŒ No DeepSeek API key found in .env file")
        return False
    
    print(f"ðŸ”‘ Using API key: {api_key[:10]}...{api_key[-5:]}")
    
    url = "https://api.deepseek.com/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "deepseek-chat",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Say 'DeepSeek API is working perfectly!' if you receive this."}
        ],
        "temperature": 0.3,
        "max_tokens": 50
    }
    
    print("ðŸ“¡ Testing DeepSeek API connection...")
    try:
        response = requests.post(url, headers=headers, json=data, timeout=10)
        
        if response.status_code == 200:
            result = response.json()
            print("âœ… SUCCESS! DeepSeek API key is valid.")
            print(f"ðŸ’¬ Response: {result['choices'][0]['message']['content']}")
            return True
        else:
            print(f"âŒ ERROR {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"âŒ ERROR: {e}")
        return False

if __name__ == "__main__":
    print("ðŸš€ Testing DeepSeek API Integration")
    print("=" * 50)
    test_deepseek_api()
