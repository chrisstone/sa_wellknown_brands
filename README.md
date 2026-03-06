# sa_wellknown_brands

A specialized toolset for generating **SpamAssassin** configuration rules designed to catch phishing and "reward" scams that spoof well-known brands.

## Overview

This repository provides a Perl-based generator that creates custom SpamAssassin rules (`.cf` files). It targets common spam patterns where a trusted brand name (e.g., "Amazon", "PayPal", "Chase") is used in the `From:name` or `Subject` line, but the actual sending email address does not belong to that brand's domain.

### Key Features

* **Brand Verification**: Matches specific brand keywords in the display name and subject.
* **False Positive Prevention**: Explicitly excludes matches if the keyword is also found in the sender's actual email address (e.g., `support@amazon.com` will not trigger the "Amazon" spam rule).
* **Lure Keyword Logic**: Automatically pairs brands with common "lure" keywords (e.g., "Winner", "Invoice", "Gift Card") to increase spam scores for high-probability phishing.
* **Automated Generation**: Uses a simple brand list and lure list to produce thousands of lines of valid SpamAssassin configuration.

---

## Files in this Repository

| File | Description |
| --- | --- |
| `brands_gen.pl` | The core Perl script (v1.1.3) that generates the `.cf` output. |
| `brands.txt` | A list of regex patterns for well-known brands across Technology, Finance, Retail, and more. |
| `lures.txt` | A list of common phishing "lure" keywords (e.g., reward, unclaimed, overdue). |
| `local_brands.cf` | The generated SpamAssassin configuration file ready for deployment. |

---

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

---

## Rule Logic

The generator produces three types of rules for every brand:

1. **Display Name Match (`__...a`)**: Triggers if the brand name is in the "Friendly" From name.
2. **Subject Match (`__...s`)**: Triggers if the brand name is in the email subject.
3. **Lure Combination**: Triggers if a Brand + a Lure keyword (like "Amazon" + "Reward") are found together, adding a compound score.

> [!IMPORTANT]
> All rules include a negative lookahead for the brand name in the `From:addr` to ensure legitimate emails from the actual brands are not flagged.

---

## Metadata

* **Author**: Chris Stone
* **Version**: 1.1.3
* 
**License**: SemVer 



Would you like me to add a section on how to contribute new brand patterns to the `brands.txt` file?