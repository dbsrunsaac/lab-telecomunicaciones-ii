close all; clear all; clc;

% info = dicominfo("covid-data.dcm")

tx = dicomread("covid-data.dcm");

imshow(tx, []);