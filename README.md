# sa_wellknown_brands

Script for generating **SpamAssassin** rules designed to catch phishing and "reward" scams that spoof well-known brands.

## Overview

This repository provides a Perl-based generator that creates custom SpamAssassin rules (`.cf` files). It targets common spam patterns where a trusted brand name (e.g., "Amazon", "PayPal", "Chase") is used in the `From:name` or `Subject` line, but the actual sending email address does not belong to that brand's domain.

## Usage

### 1. Prepare your lists

Ensure `brands.txt` and `lures.txt` are populated with the patterns you wish to target.

**Example `brands.txt` entry:**

```text
amazon
pay.?pal

```

**Example `lures.txt` entry:**

```text
reward
invoice

```

### 2. Run the Generator

Execute the Perl script to build your configuration file:

```bash
perl brands_gen.pl

```

### 3. Deploy to SpamAssassin

Copy the resulting `local_brands.cf` to your SpamAssassin configuration directory (typically `/etc/mail/spamassassin/`) and restart the SpamAssassin service:

```bash
cp local_brands.cf /etc/mail/spamassassin/
spamassassin --lint
systemctl restart spamassassin

```
