import requests
from typing import List
from schemas.schemas import PillInfo, PillInfoDetail
from db.database import get_db
from sqlalchemy.orm import Session
from fastapi import Depends

#약 정보가 리스트로 뜸
def search_pill(search_word: str, db: Session = Depends(get_db)) -> List[PillInfo]:
    """약 정보 검색"""
    url = "https://www.health.kr/searchDrug/ajax/ajax_commonSearch.asp"
    params = {
        'search_word': search_word,
        'search_flag': 'all'
    }
    response = requests.get(url, params=params) # 약 정보 검색 요청
    if response.status_code == 200:
        pill_info = []
        for item in response.json():
            pill_info.append(PillInfo(
                    drug_code=item['drug_code'],
                    drug_name=item['drug_name'],
                    pack_img=item['pack_img'],
                    dosage=item['dosage'],
                    effect=item['effect']
                ))
        return pill_info
    else:
        return []

def get_pill_info_detail(drug_code: str, db: Session = Depends(get_db)) -> PillInfoDetail:
    """약 상세 정보 조회"""
    url = 'https://www.health.kr/searchDrug/ajax/ajax_result_drug2.asp'
    params = {
        'drug_cd': drug_code
    }
    response = requests.get(url, params=params)
    response_json = response.json()
    print(response_json)
    pill_info_detail = PillInfoDetail(
        drug_code=response_json['drug_code'],
        drug_name=response_json['drug_name'],
        pack_img=response_json['pack_img'],
        dosage=response_json['dosage'],
        effect=response_json['effect'],
        caution=response_json['caution']
    )
    return pill_info_detail