import requests

url = "https://www.health.kr/searchDrug/ajax/ajax_commonSearch.asp"

params = {
    'search_word': "타이레놀정500mg",
    'search_flag': "all"
}

responses = requests.get(url=url, params=params)
for response in responses.json():
    print(response.keys())