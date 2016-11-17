#!/bin/bash
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart cisd.service
systemctl restart docker.service

