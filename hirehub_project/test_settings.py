
import urllib.request
import urllib.error
import json

def test_settings_api():
    url = 'http://127.0.0.1:8000/adminpanel/api/platform-settings/'
    print(f"Testing {url} ...")
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            print(f"Status Code: {response.status}")
            data = response.read()
            try:
                print(json.loads(data))
            except:
                print(data)
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print("Error Content:")
        print(e.read().decode('utf-8')[:2000])
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    test_settings_api()
