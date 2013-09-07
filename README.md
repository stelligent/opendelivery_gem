opendelivery_gem
================

Ruby Gem for OpenDelivery. For information on our feature roadmap, go to the [Roadmap](https://github.com/stelligent/opendelivery_gem/blob/master/ROADMAP.md)

==============

## Description

OpenDelivery gem lets you interact with the open delivery components for orchestrating your software delivery using the Open Delivery platform.

While Ruby can be installed on many operating systems, we've included detailed instructions for installing on an AWS linux instance. With minor alterations, you can run these instructions for other operating systems.

## Configuration of AWS Linux instance

Since you will be using [AWS EC2](https://console.aws.amazon.com/ec2/) to install AWS. You'll need to create an instance using the AWS linux instance. The AMI ID to use is:

```
us-east-1: ami-05355a6c
us-west-1: ami-951945d0
us-west-2: ami-16fd7026
eu-west-1: ami-24506250
sa-east-1: ami-3e3be423
ap-southeast-1: ami-74dda626
ap-northeast-1: ami-dcfa4edd
```

## Create your AWS Config file

```
AWS.config(
:access_key_id => "AKIAISHDASD7MBC7fHA",
:secret_access_key => "vEUt0O/UZkDDC2sa/44wAaZ7uHASDASDbStfgujiInFF",
:region => "us-west-1")
```

## Install Ruby and its dependencies

1. ```yum -y install ruby19```

## Install Opendelivery gem

1. ```gem install opendelivery```
or add it to your gemfile

## LICENSE

Copyright (c) 2013 Stelligent Systems LLC

MIT LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
