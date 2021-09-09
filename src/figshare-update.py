#!/usr/bin/env python

import hashlib
import json
import os

import requests
from requests.exceptions import HTTPError

from pathlib import Path


BASE_URL = 'https://api.figshare.com/v2/{endpoint}'
# need a security token for your figshare account to use the API
# this one is under a gitignore so its not shared to the github
TOKEN = Path('areadata-token.txt').read_text()
TOKEN = TOKEN.replace('\n', '')
CHUNK_SIZE = 1048576

ARTICLE_ID = '16587311' # can be retrieved from an account with list_articles()


def raw_issue_request(method, url, data=None, binary=False):
    headers = {'Authorization': 'token ' + TOKEN}
    if data is not None and not binary:
        data = json.dumps(data)
    response = requests.request(method, url, headers=headers, data=data)
    try:
        response.raise_for_status()
        try:
            data = json.loads(response.content)
        except ValueError:
            data = response.content
    except HTTPError as error:
        print('Caught an HTTPError: {}'.format(error.message))
        print('Body:\n', response.content)
        raise

    return data


def issue_request(method, endpoint, *args, **kwargs):
    return raw_issue_request(method, BASE_URL.format(endpoint=endpoint), *args, **kwargs)


def list_articles():
    result = issue_request('GET', 'account/articles')
    print('Listing current articles:')
    if result:
        for item in result:
            print(u'  {url} - {title}'.format(**item))
    else:
        print('  No articles.')
    print


def create_article(title):
    data = {
        'title': title  # You may add any other information about the article here as you wish.
    }
    result = issue_request('POST', 'account/articles', data=data)
    print('Created article:', result['location'], '\n')

    result = raw_issue_request('GET', result['location'])

    return result['id']


def list_files_of_article(article_id):
    result = issue_request('GET', 'account/articles/{}/files'.format(article_id))
    print('Listing files for article {}:'.format(article_id))
    if result:
        for item in result:
            print('  {id} - {name}'.format(**item))
    else:
        print('  No files.')

    print


# TS - trying to list filenames in a format that we can then choose to delete
def list_files_to_delete(article_id):
    result = issue_request('GET', 'account/articles/{}/files'.format(article_id))
    print('Listing files for article {}:'.format(article_id))
    if result:
        files = []
        for item in result:
            print('{id}'.format(**item))
            files.append('{id}'.format(**item))
        return files
    else:
        print('  No files.')


def get_file_check_data(file_name):
    with open(file_name, 'rb') as fin:
        md5 = hashlib.md5()
        size = 0
        data = fin.read(CHUNK_SIZE)
        while data:
            size += len(data)
            md5.update(data)
            data = fin.read(CHUNK_SIZE)
        return md5.hexdigest(), size


def initiate_new_upload(article_id, file_name):
    endpoint = 'account/articles/{}/files'
    endpoint = endpoint.format(article_id)

    md5, size = get_file_check_data(file_name)
    data = {'name': os.path.basename(file_name),
            'md5': md5,
            'size': size}

    result = issue_request('POST', endpoint, data=data)
    print('Initiated file upload:', result['location'], '\n')

    result = raw_issue_request('GET', result['location'])

    return result


def complete_upload(article_id, file_id):
    issue_request('POST', 'account/articles/{}/files/{}'.format(article_id, file_id))


def upload_parts(file_info, file_path):
    url = '{upload_url}'.format(**file_info)
    result = raw_issue_request('GET', url)

    print('Uploading parts:')
    with open(file_path, 'rb') as fin:
        for part in result['parts']:
            upload_part(file_info, fin, part)
    print


def upload_part(file_info, stream, part):
    udata = file_info.copy()
    udata.update(part)
    url = '{upload_url}/{partNo}'.format(**udata)

    stream.seek(part['startOffset'])
    data = stream.read(part['endOffset'] - part['startOffset'] + 1)

    raw_issue_request('PUT', url, data=data, binary=True)
    print('  Uploaded part {partNo} from {startOffset} to {endOffset}'.format(**part))


def delete_item(article_id, file_id):
    print('Deleting item')
    issue_request('DELETE', 'account/articles/{}/files/{}'.format(article_id, file_id))


def main():
    # We are going to delete all the files in the article (specified above)
    # then replace them with the newly created GID2 files
    list_files_of_article(ARTICLE_ID)

    # delete all of the files!
    del_files = list_files_to_delete(ARTICLE_ID)

    # now iterate across the list of files and delete each
    for i in del_files:
        delete_item(ARTICLE_ID, i)
        list_files_of_article(ARTICLE_ID)

    # Then we upload the new files
    print('Uploading Temperature Data')
    file_info = initiate_new_upload(ARTICLE_ID, 'output/temp-dailymean-GID2-cleaned.RDS')
    # Until here we used the figshare API; following lines use the figshare upload service API.
    upload_parts(file_info, 'output/temp-dailymean-GID2-cleaned.RDS')
    # We return to the figshare API to complete the file upload process.
    complete_upload(ARTICLE_ID, file_info['id'])

    file_info = initiate_new_upload(ARTICLE_ID, 'output/temp-dailymean-GID2-cleaned.zip')
    upload_parts(file_info, 'output/temp-dailymean-GID2-cleaned.zip')
    complete_upload(ARTICLE_ID, file_info['id'])

    print('Uploading Specific Humidity Data')
    file_info = initiate_new_upload(ARTICLE_ID, 'output/spechumid-dailymean-GID2-cleaned.RDS')
    upload_parts(file_info, 'output/spechumid-dailymean-GID2-cleaned.RDS')
    complete_upload(ARTICLE_ID, file_info['id'])

    file_info = initiate_new_upload(ARTICLE_ID, 'output/spechumid-dailymean-GID2-cleaned.zip')
    upload_parts(file_info, 'output/spechumid-dailymean-GID2-cleaned.zip')
    complete_upload(ARTICLE_ID, file_info['id'])

    print('Uploading Relative Humidity Data')
    file_info = initiate_new_upload(ARTICLE_ID, 'output/relhumid-dailymean-GID2-cleaned.RDS')
    upload_parts(file_info, 'output/relhumid-dailymean-GID2-cleaned.RDS')
    complete_upload(ARTICLE_ID, file_info['id'])

    file_info = initiate_new_upload(ARTICLE_ID, 'output/relhumid-dailymean-GID2-cleaned.zip')
    upload_parts(file_info, 'output/relhumid-dailymean-GID2-cleaned.zip')
    complete_upload(ARTICLE_ID, file_info['id'])

    print('Uploading UV Data')
    file_info = initiate_new_upload(ARTICLE_ID, 'output/uv-dailymean-GID2-cleaned.RDS')
    upload_parts(file_info, 'output/uv-dailymean-GID2-cleaned.RDS')
    complete_upload(ARTICLE_ID, file_info['id'])

    file_info = initiate_new_upload(ARTICLE_ID, 'output/uv-dailymean-GID2-cleaned.zip')
    upload_parts(file_info, 'output/uv-dailymean-GID2-cleaned.zip')
    complete_upload(ARTICLE_ID, file_info['id'])

    print('Uploading Precipitation Data')
    file_info = initiate_new_upload(ARTICLE_ID, 'output/precip-dailymean-GID2-cleaned.RDS')
    upload_parts(file_info, 'output/precip-dailymean-GID2-cleaned.RDS')
    complete_upload(ARTICLE_ID, file_info['id'])

    file_info = initiate_new_upload(ARTICLE_ID, 'output/precip-dailymean-GID2-cleaned.zip')
    upload_parts(file_info, 'output/precip-dailymean-GID2-cleaned.zip')
    complete_upload(ARTICLE_ID, file_info['id'])
    
    # End by listing the files in the article now
    list_files_of_article(ARTICLE_ID)


if __name__ == '__main__':
    main()