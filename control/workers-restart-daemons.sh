#!/bin/bash

systemctl restart nginx.service
systemctl restart cisd.service
systemctl restart docker.service

