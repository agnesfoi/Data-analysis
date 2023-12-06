
# coding: utf-8

# **Import**

import pandas as pd
from bs4 import BeautifulSoup
import requests
import re
from xml.etree import ElementTree as ET
import time

# **Import the ratings**

def import_ratings(ID):
    API_url_head = 'https://www.aroma-zone.com/info/comments/'
    API_url_tail = '/ajax/num?cms_ajax=1'
    #recipe_id = home_soup.find_all(class_ = "selection-book") #idnum['value']
    API_url = API_url_head+ID+API_url_tail
    try:
        response = requests.post(API_url, data='#ajax-comments-num')
        grade_soup = BeautifulSoup(response.content, 'html.parser')
        votes = grade_soup.find(class_ = 'total-votes').get_text()
        ratings = grade_soup.find(class_ = "average-rating").get_text()
    except AttributeError:
        votes = 'NA'
        ratings = 'NA'
    return ratings,votes

def import_comments(ID):
    url_head = 'https://www.aroma-zone.com/info/comments/'
    url_tail = '/all'
    page = requests.get(url_head+ID+url_tail)
    if not page.status_code == 200:
        print('cannot access comments: '+html)
        return []
    soup = BeautifulSoup(page.content, 'html.parser')
    comments = []
    for s in soup.find_all(class_ = "comment small "):
        comment = {}
        comment['title'] = s.find(class_ = "title").get_text()
        comment['content'] = s.find(class_ = "comment-content").get_text()
        comment['rating'] = s.find(itemprop="ratingValue").get("content")
        comments.append(comment)
    return comments

# **Explore 1 recipe**

def import_1_page(html):

    page = requests.get(html)
    if not page.status_code == 200:
        print('cannot access '+html)
    soup = BeautifulSoup(page.content, 'html.parser')
    #print(soup.prettify())

    recipe = {}

    #Title
    recipe['title'] = soup.find(class_ = 'title').get_text()

    #ID
    ID = soup.select('div[class*="node recipe recipe-cosmetique"]')[0]['id']
    ID = re.sub("[^0-9]", "", ID)

    #date
    recipe['date'] = soup.find(class_ = "recipe-ref").get_text()

    #ratings and votes
    ratings,votes = import_ratings(ID)
    recipe['ratings'] = ratings
    recipe['votes'] = votes

    #comments
    recipe['comments'] = import_comments(ID)
        
    #Price, difficulty, preparation time and conservation
    keys = ['price','difficulty','preparation_time','conservation']
    for s,key in zip(soup.find_all(class_ = 'libelle'),keys):
        recipe[key] = s.get_text()
   
    #Product category
    recipe['technical_family'] = []
    s = soup.find(class_ = 'tabs-recipe technical-family')
    S = list(s.children)
    for s2  in S:
        try:
            recipe['technical_family'].append(s2.get_text())
        except:
            pass

    #Skin type
    recipe['skin_type'] = []
    s = soup.find_all(class_ = "tabs-recipe skin-type")
    for s2 in s:
        s2 = s2.get_text().translate({ord(i):None for i in '\n\t'})
        recipe['skin_type'].append(s2)     
        
    #Benefits change
    recipe['benefits'] = []
    s = soup.find_all(class_ = "picto bienfait")
    for s2 in s:
        recipe['benefits'].append(s2.find('img')['alt'])
        
    #Problems
    recipe['problems'] = []
    s = soup.find_all(class_ = "picto probleme-specifique")
    for s2 in s:
        recipe['problems'].append(s2.find('img')['alt'])

    #Ingredients
    recipe['ingredients'] = []
    #s = soup.find_all(class_ = "cell-ingredient")
    tables = pd.read_html(html) # Returns list of all tables on page
    ingredients = tables[0] # Select table of interest
    headers = ingredients.columns
    recipe['ingredients'] = ingredients.to_dict('list')

    # Precaution
    #s = soup.find(class_ = 'blocks block-bulle-right').get_text()
    #lookfor = "Précautions : \n"
    #indstart = s.find(lookfor)
    #indend=  s.find('\n', indstart+len(lookfor)+1)
    #recipe['precautions'] = s[indstart+len(lookfor):indend]
    
    # Utilisation
    #s = soup.find(class_ = 'blocks block-bulle-right').get_text()
    #lookfor = "Utilisation : \n"
    #indstart = s.find(lookfor)
    #indend=  s.find('\n', indstart+len(lookfor)+1)
    #recipe['utilisation'] = s[indstart+len(lookfor):indend]
    
    # Preparation-Utilisation-Precaution-Allergens
    recipe['PUP'] = []
    s = soup.find_all(class_ = "blocks block-bulle-right")
    for s2 in s:
        s2 = s2.get_text().translate({ord(i):None for i in '\n\t'})
        recipe['PUP'].append(s2) 
 
    #Allergens
    s = soup.find(class_ = 'blocks block-bulle-right').get_text()
    lookfor = "Liste d'allergènes : \n"
    indstart = s.find(lookfor)
    indend=  s.find('\n', indstart+len(lookfor)+1)
    recipe['allergens'] = s[indstart+len(lookfor):indend]

    print('successfully imported {0}'.format(html))
    return recipe
