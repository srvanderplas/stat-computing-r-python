import os
import re
from dotenv import load_dotenv
from pathlib import Path
from openai import OpenAI
from bs4 import BeautifulSoup

# Load OPENAI API KEY
load_dotenv()


def node_to_text(div):
  node_subsecs = div.findChildren('section', recursive = False)
  if len(node_subsecs) == 0:
    tmp_txt = ' '.join(div.stripped_strings)
    tmp_txt = re.sub(r'\xa0',' ', tmp_txt)
    if (len(tmp_txt) > 4096):
      tmp_txt = [node_to_text(i) for i in div.findChildren(recursive = False)]
  else:
    tmp_txt = [node_to_text(i) for i in node_subsecs]
  return tmp_txt

def flatten(A):
    rt = []
    for i in A:
        if isinstance(i,list): rt.extend(flatten(i))
        else: rt.append(i)
    return rt

def clean_html(soup):
  # Remove callouts - usually code related
  for div in soup.findAll(attrs={'class':"callout"}):
    ref_replace_txt = soup.new_tag('p')
    ref_replace_txt.string = "Please see the online version of the book for code examples."
    div.clear()
    div.insert_after(ref_replace_txt)
  # Remove tabsets - usually code related
  for div in soup.findAll(attrs={'class':"panel-tabset"}):
    ref_replace_txt = soup.new_tag('p')
    ref_replace_txt.string = "Please see the online version of the book for code examples."
    div.clear()
    div.insert_after(ref_replace_txt)
  # Don't transcribe references...
  for div in soup.findAll(id = 'refs'):
    ref_replace_txt = soup.new_tag('p')
    ref_replace_txt.string = "Please see the online version of the book for the reference list."
    div.clear()
    div.insert_after(ref_replace_txt)
  
  return soup

  
  
# Get text from rendered html file
url = "docs/part-tools/04-scripts-notebooks.html"
html = open(url).read()
soup = BeautifulSoup(html, features="html.parser")
# Clean html to replace un-readable info with text referring to the book
soup = clean_html(soup)
main_body = soup.find(id = "quarto-document-content")
# Split document into sections to clean
subsecs = main_body.findChildren('section', recursive = False)
clean_text = [node_to_text(i) for i in subsecs]
# Flatten list to make it easy to turn into audio
clean_text2 = flatten(clean_text)

os.environ["OPENAI_API_KEY"] = os.environ.get("OPENAI_API_KEY")
client = OpenAI()

for i in range(len(clean_text2)):
  speech_file_path = f"audio/part-tools/04-scripts-notebooks-{i:02}.mp3"
  response = client.audio.speech.create(
    model="tts-1",
    voice="shimmer",
    input=clean_text2[i]
  )
  response.write_to_file(speech_file_path)
  print(speech_file_path)

