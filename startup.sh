docker run -dt -p 9000:80 -p 45566:45566 -p 9527:9527/udp  --net=htpc_network --name=rtorrentcontainer --dns 8.8.8.8  -v /home/cloudsto/rtorrent/:/rtorrent -v /media/data/:/media_data docktorrent
