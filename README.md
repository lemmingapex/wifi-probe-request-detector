# WIFI Probe Request Detector
This small script uses [tshark](https://www.wireshark.org/docs/man-pages/tshark.html) to detect wifi probe requests from anything looking for wifi such as phones and tables.

```
MAC Address          SSID                           Last Seen           Packet Count Average RSSI
-------------------- ------------------------------ ------------------- ------------ ------------
Apple_d9:5d:49       GUEST_ACCESS                   2017/06/19 07:25:29  34             -43.06
Apple_8a:69:8d       CCCC-OPEN                      2017/06/18 20:43:14  3              -76.67
Apple_3d:87:1e       Free Wi-Fi                     2017/06/18 17:38:56  111            -48.73
88:e6:50:05:91:01    tapas                          2017/06/19 07:45:28  2              -30.00
Apple_3d:87:1e       United_Wi-Fi                   2017/06/18 17:38:45  7              -49.14
4e:df:90:31:e7:b4    BOSCO                          2017/06/19 07:50:08  9              -62.44
9c:d9:17:3b:34:b8    XFINITYWIFI                    2017/06/19 09:08:45  550            -60.19
4e:df:90:31:e7:b4    C_CORP                         2017/06/19 09:08:51  27             -63.25
```

## Prerequisites

You should run the perl script on linux as root (do not sudo).  Tested on unbuntu.  
You need to install [tshark](https://www.wireshark.org/docs/man-pages/tshark.html) and put it on your path.  
You should have both ifconfig and iwconfig on your path.  

## How to Run

```
./probe-request-detector.pl
```

By default the perl script will use the interface named wlan0.  When killed, the script will write a file, probe-request-detector-output.txt, that contains an overview of what was detected.

```
./probe-request-detector.pl --interface=wlan1 --outfile=wlan1_output.txt
```
## About

The script will put your wifi chipset into monitor mode and then listen for probe requests.  The script changes the wifi channel every four seconds to monitor the traffic over a larger range of frequencies.
