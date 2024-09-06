import cv2
import numpy as np
import face_recognition
import os
import pickle
import requests
import json
from datetime import datetime

os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "rtsp_transport;udp"

esp8266ip = "http://192.168.1.249"

path = "/Users/raghavsharma/Documents/Home security/images"
serverToken = 'AAAAUiUzPCo:APA91bHD_auTHDAUfjlZGr9cX_jnYv99nJ4c8nh-8NBVGXNEu8LhqMLR6JijO0K8Ns4pN6RTmA_Vs85t1VTiC8-4Ah4zsL5S1pDLvF6xqf2hqZ19LYHYVMwI8y6SBwiQJZlea40joVwl'
deviceToken = 'e4YM85imSZWt_EzLf8j5Oi:APA91bFGFjrA0Uno3sg73afgazvgPik2cEH0gkUuavnfoPNuE0cPijYpskl9cLTS04K_vzKpAnBi_h4iE2Qq4Q26NgwemBmWFX-nHmMDXfdzBuWXLRTuKCdLwV8VyCpaLMt8J4Lr8r7D'
headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=' + serverToken,
      }

body = {
          'notification': {'title': 'Alert',
                            'body': 'Unknown person detected...'
                            },
          'to':
              deviceToken,
          'priority': 'high',
        }

images = os.listdir(path)
loadedImages = []
names = []
encodingsList = []



# Here We capture image
def captureImage(name):
    cam = cv2.VideoCapture(2)
    # cam = cv2.VideoCapture("rtsp://admin:Krishna%40429@192.168.1.21/Streaming/Channels/101", cv2.CAP_FFMPEG)
    cv2.namedWindow("Capture image")

    while True:
        result, image = cam.read()
        if not result:
            print("failed to capture")
            break
        cv2.imshow("Captured image",image)
        
        k = cv2.waitKey(1)
        if k%256 == 32:
            # SPACE pressed
            cv2.imwrite(path+'/'+name+'.png', image)
            cv2.waitKey(0)
            cv2.destroyWindow("Captured image")
            break
            
    cam.release()


# Loading images in proper format to encode
def loadImages():
    images = os.listdir(path)
    for img in images:
        curImg = face_recognition.load_image_file(path+'/'+img)
        loadedImages.append(curImg)
        names.append(img.split(".")[0])

# To encode each image in file and saving the encodings for future use
def encodeImage(name):
    loadImages()
    for img in loadedImages:
        img = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
        encode = face_recognition.face_encodings(img)[0]
        encodingsList.append(encode)

    encodingDic = {}
    with open('encodings', 'wb') as f:
        for i in range(0,len(encodingsList)):
            encodingDic[names[i]]=encodingsList[i]
        pickle.dump(encodingDic,f)
    

def loadEncodings():
    with open('encodings', 'rb') as fl:
        encodingDic = pickle.load(fl)
        encodingDic = dict(encodingDic)

    for name, encodings in encodingDic.items():
        names.append(name)
        encodingsList.append(encodings)

    del encodingDic


# if no images found. We need to train our first image
if len(images)==0:
    print("Enter your name :- ")
    name = input()  
    captureImage(name)
    encodeImage(names)


loadEncodings()
# cap = cv2.VideoCapture("rtsp://admin:Krishna%40429@192.168.1.21/Streaming/Channels/101", cv2.CAP_FFMPEG)
cap = cv2.VideoCapture(2)   
arrivalList = {}
i=0
while cap.isOpened():
    success, img = cap.read()
    imgS = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
    # Detecting all faces in current faces
    facesCurFrame = face_recognition.face_locations(imgS)
    if(facesCurFrame):
        print('\n')
    else:
        print('no face')
        requests.get(esp8266ip+'/lockState?lockClose=1')
        arrivalList = {}
    
    encodeCurFrame = face_recognition.face_encodings(imgS, facesCurFrame)

    if encodeCurFrame and facesCurFrame:
        matches = face_recognition.compare_faces(encodingsList, encodeCurFrame[0])
        faceDis = face_recognition.face_distance(encodingsList, encodeCurFrame[0])
        matchIndex = np.argmin(faceDis)
        y1,x2,y2,x1 = facesCurFrame[0]
        flag = 0

        

        if(faceDis[matchIndex] > 0.45):
            
            requests.get(esp8266ip+'/lockState?lockClose=1')
            now = datetime.now()
            dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
 

            body = {
          'notification': {'title': 'Unkown Person',
                            'body': dt_string
                            },
          'to':
              deviceToken,
          'priority': 'high',
        }
            print('Unknown person is waiting at door')
            response = requests.post("https://fcm.googleapis.com/fcm/send",headers = headers, data=json.dumps(body))
            print(response.status_code)
            print(response.json())
            flag = 1

        else :
            if matches[matchIndex]:
                name = names[matchIndex].upper()
                if name not in arrivalList.keys() or arrivalList[name]==-1:
                    requests.get(esp8266ip+'/lockState?lockOpen=1')
                    now = datetime.now()
                    dt_string = now.strftime("%d/%m/%Y %H:%M:%S")
 
                    body1 = {
                                'notification': {'title': name,
                                'body': dt_string
                                },
                            'to':
                                    deviceToken,
                                'priority': 'high',
                                    
                            }
                    response1 = requests.post("https://fcm.googleapis.com/fcm/send",headers = headers, data=json.dumps(body1))
                    print(response1.status_code)
                   
                print(name)
                print(faceDis[matchIndex])

                i = (i+1)%100
                if name not in arrivalList.keys() or arrivalList[name] == -1:
                    arrivalList[name] = i

                for n in arrivalList.keys():
                    if arrivalList[name] == i+1:
                        arrivalList[n] = -1

                y1,x2,y2,x1 = facesCurFrame[0]

                cv2.rectangle(img,(x1,y1),(x2,y2),(0,255,0),2)
                cv2.rectangle(img,(x1,y2-35),(x2,y2),(0,255,0),cv2.FILLED)
                cv2.putText(img,name,(x1+6,y2-6),cv2.FONT_HERSHEY_COMPLEX,1,(255,255,255),)
        if(flag == 1):
            cv2.imshow('UnknownPerson',img)
            print('Do you know this person? y/n')
            cv2.waitKey(1000)
            inp = input()

            if inp == 'y' or inp == 'Y':
                print('Enter name:- ')
                name = input()
                cv2.imwrite(path+'/'+name+'.png', img)
                encodeImage(names)
                loadEncodings()
                requests.get(esp8266ip+'/lockState?lockOpen=1')
                body1 = {
                            'notification': {'title': name,
                            'body': dt_string
                        },
                            'to':
                                    deviceToken,
                                'priority': 'high',
                                  
                            }
                response1 = requests.post("https://fcm.googleapis.com/fcm/send",headers = headers, data=json.dumps(body1))
            elif inp == 'n' or inp == 'N':
                continue
            else:
                print('invalid input')
            cv2.destroyAllWindows()
                
        else:
            cv2.imshow('WebCam', img)
    
            cv2.waitKey(30)
            