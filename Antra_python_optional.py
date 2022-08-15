#!/usr/bin/env python
# coding: utf-8

# In[3]:


import os, uuid
import sys
from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient, __version__
import csv


connection_string = "DefaultEndpointsProtocol=https;AccountName=antrablobstorage;AccountKey=ECVP9sDWl64Ubd6w3lGd4d4fbiZuwHWWu1q/KoS2sCR18mwwkSxf1gLC7PvqCT1jWi3IYE87ZQtJYMIztIg3vg==;EndpointSuffix=core.windows.net"
blob_svc = BlobServiceClient.from_connection_string(conn_str=connection_string)


print("\nList blobs in the container")
with open('optional.csv', 'w') as f:
    container_client = blob_svc.get_container_client("imagescontainer")
    blob_list = container_client.list_blobs()
    for blob in blob_list:
        print("\t Blob name: "+"imagescontainer" +'/'+  blob.name) #this will print on the console
        f.write('/'+blob.name) #this will write on the csv file just the blob name
        f.write('\n')   


# In[ ]:




