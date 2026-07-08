---
adr: 3
date: 2026-03-01
title: Storage used for large unstructured loads of data
status: Accepted
type: Backend, Storage
---

## Context and Problem Statement

We needed to provide a large storage that allows to store massive loads of data for purposes such as storing videos and photos, but also for storing application backup data. Besides k8s cluster there is an external ZFS server that we plan to use for this purpose. The storage itself does not require to be relatively fast but it needs to be easy to use and expand in the future. In order to achieve that we plan to use an S3 storage due to it's ease of use and flexibility

## Considered Options

### RustFS

**Rejected**: Project is currently in a very early phase and has poor documentation

### SeaweedFS

**Accepted**: SeaweedFS allows to set up multiple masters, has and admin UI, allows to create both volumes and S3 buckets. Has snapshoting capabilities, user and group management.

## Decision Outcome

We installed **SeaweedFS** to create S3 bucket on it that are used by various applications. For each application new user with token is created so that only this application can make any changes to that specific bucket. 