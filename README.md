![DK Hostmaster Logo](https://www.dk-hostmaster.dk/sites/default/files/dk-logo_0.png)

# DKHM RFC for AuthInfo

![Markdownlint Action](https://github.com/DK-Hostmaster/DKHM-RFC-AuthInfo/workflows/Markdownlint%20Action/badge.svg)
![Spellcheck Action](https://github.com/DK-Hostmaster/DKHM-RFC-AuthInfo/workflows/Spellcheck%20Action/badge.svg)

2020-11-21 Revision: 2.0

## Table of Contents

<!-- MarkdownTOC bracket=round levels="1,2,3,4" indent="  " autolink="true" autoanchor="true" -->

- [Introduction](#introduction)
  - [About this Document](#about-this-document)
  - [License](#license)
  - [Document History](#document-history)
  - [XML and XSD Examples](#xml-and-xsd-examples)
- [Description](#description)
  - [Setting and Unsetting the AuthInfo Token](#setting-and-unsetting-the-authinfo-token)
  - [Fetching the AuthInfo via EPP](#fetching-the-authinfo-via-epp)
  [AuthInfo Token Format](#authinfo-token-format)
- [XSD Definition](#xsd-definition)
- [References](#references)

<!-- /MarkdownTOC -->

<a id="introduction"></a>
## Introduction

This is a draft and proposal for a handling authorizations (AuthInfo, authorization token) via the DK Hostmaster EPP, Registrar-portal (RP) and self-service (SB) portals/services.

- The goal is to make implement temporary authorizations using **AuthInfo** token for operations that require 3rd. party involvement
- The following processes has been identified: change registrar (transfer in EPP)

Additional requirements have been identified:

- An active **AuthInfo** token expires if the registrant is changed
- An active **AuthInfo** token expires when a name server change is executed successfully.
- An active **AuthInfo** token expires automatically after 14 days
- Only one **AuthInfo** token is available and active at a given time if any
- **AuthInfo** token can be retrieved via the following portals: EPP, RP and SB, by the users holding the privilege to view and administer authorizations for the given domain name

<a id="about-this-document"></a>
### About this Document

We have adopted the term RFC (_Request For Comments_), due to the recognition in the term and concept, so this document is a process supporting document, aiming to serve the purpose of obtaining a common understanding of the proposed implementation and to foster discussion on the details of the implementation. The final specification will be lifted into the [DK Hostmaster EPP Service Specification][DKHMEPPSPEC] implementation and this document will be closed for comments and the document will no longer be updated.

The working title for this initiative was **AuthID**, we have later adopted the term **AuthInfo** and refer to the actual mechanism as **AuthInfo** token for easier mapping with existing and standard EPP RFC terminology. Do note the term **AuthID** might appear in examples, documentation and filenames, this can be exchanged for **AuthInfo** and **AuthInfo** token where appropriate.

The RFC was primarily aimed at name server changes, but the scope has changed based on feedback on the proposed process and it has somewhat been superseded by the initiative ["New basis for collaboration between registrars and DK Hostmaster"][CONCEPT] available on the DK Hostmaster website.

This document now focuses solely on the handling of authorisations, in the implementation form of AuthInfo tokens. The processes relying on use of authorizations are documented in separate RFCs, which currently is limited to:

1. ["DKHM RFC for Transfer Domain EPP Command"][DKHMRFCTRANSFER]

This document is not the authoritative source for business and policy rules and possible discrepancies between this an any authoritative sources are regarded as errors in this document. This document is aimed at the technical specification and possible implementation and is an interpretation of authoritative sources and can therefor be erroneous.

<a id="license"></a>
### License

This document is copyright by DK Hostmaster A/S and is licensed under the MIT License, please see the separate LICENSE file for details.

<a id="document-history"></a>
### Document History

- 2.0 2020-11-23
  - Removed information related to name server change, the AuthInfo handling is intact and has not been changed, except for the keyword used for generating/setting the AuthInfo token
  - The changes related to the `update domain` command processing has also been removed
  - Addition of additional links to resources
  - Correction to links pointing to redundant resources

- 1.2 2020-09-19
  - Addition of disclaimer

- 1.1 2020-09-16
  - Added note on the handling of DSRECORDs

- 1.0 2020-09-16
  - First proper revision

<a id="xml-and-xsd-examples"></a>
### XML and XSD Examples

All example XML files are available in the [DK Hostmaster EPP XSD repository][DKHMXSDSPEC].

The proposed extensions and XSD definitions are available in version [4.0][DKHMXSD4.0] of the DK Hostmaster XSD, which is currently marked as a _pre-release_.

The referenced XSD version is not deployed at this time and is only available in the [EPP XSD repository][DKHMXSDSPEC], it might be surpassed by a newer version upon deployment of the EPP service implementing the proposal, please refer to the revision of [EPP Service Specification][DKHMEPPSPEC] describing the implementation.

<a id="description"></a>
## Description

The extension is made to `domain:update`. The `domain:update` command supports several different operations (interpreted as sub-commands):

- change registrant for domain
- add name server to domain
- remove name server from domain
- add admin contact
- remove admin contact
- add billing contact
- remove billing contact

And as proposed in this RFC:

- setting of **AuthInfo** token
- unsetting of **AuthInfo** token

<a id="setting-and-unsetting-the-authinfo-token"></a>
### Setting and Unsetting the AuthInfo Token

Setting the **AuthInfo** is as described above also expected to be handled by the `update domain` command, since this is the sole command working on the domain object in general.

Setting the **AuthInfo** via EPP is expected to be accomplished using the following example, where the keyword will point to the requested authorization and hence initiates the generation of a new **AuthInfo** token, please see separate RFCs implementing this, ["DKHM RFC for Transfer Domain EPP Command"][DKHMRFCTRANSFER], being the sole candidate at the time of writing.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:chg>
          <domain:authInfo>
            <domain:pw>KEYWORD</domain:pw>
          </domain:authInfo>
        </domain:chg>
      </domain:update>
    </update>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`update_domain_set_authid.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/update_domain_set_authid.xml)

1. This implementation can be contained to the standard EPP specification
1. The operation is not particularly explicit about what it does

![diagram set auth-id process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/set_auth-id_proces-2.0.png)

The **AuthInfo** token and hence the authorization is proposed to have a lifespan of 14 days. The requestor (_setter_) of a an **AuthInfo** might however have an interest in ending the life of a **AuthInfo** token prematurely.

Here an an example outlining the suggestion for implementation of usage pattern, where the `update domain` command can be used for exactly that:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:chg>
          <domain:authInfo>
            <domain:null>
          </domain:authInfo>
        </domain:chg>
      </domain:update>
    </update>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`update_domain_unset_authid.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/update_domain_unset_authid.xml)

The above outline is matching the description in RFC:5731

> A <domain:null> element can be used within the <domain:authInfo> element to remove authorization information.

The command simply unsets (_removes/clears_) an **AuthInfo** token if it exists.

1. This implementation can be contained to the standard EPP specification
1. The operation is not particularly explicit about what it does

![diagram unset auth-id process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/unset_auth-id_proces-2.0.png)

Generally the two operations will support the following use-cases:

- `set` will let the requester request the generation of an **AuthInfo** token for the given domain
- and `unset` will let the requester invalidate a previously set **AuthInfo** token for the given domain

:wrench: a clarification is required if an error/warning should be emitted if no **AuthInfo** token is deleted.

<a id="fetching-the-authinfo-via-epp"></a>
### Fetching the AuthInfo via EPP

When the **AuthInfo** token has been set it can be retrieved via the EPP command: `info domain` or via similar detailed information points in the RP or SB portals, do note that the retrieval requires authorization and therefor authentication and controlled access (AAA).

The **AuthInfo**, if set will be reflected in the response to the request, together with an extension so communicate the expiration date of the **AuthInfo** token. Please see the XSD definition below.

`domain info` request example:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <info>
      <domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name hosts="all">example.com</domain:name>
      </domain:info>
    </info>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`info_domain.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/info_domain.xml)

And the `info domain` response if a **AuthInfo** is present.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <response>
    <result code="1000">
      <msg>Command completed successfully</msg>
    </result>
    <resData>
      <domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:roid>EXAMPLE1-REP</domain:roid>
        <domain:status s="ok"/>
        <domain:registrant>jd1234</domain:registrant>
        <domain:contact type="admin">sh8013</domain:contact>
        <domain:contact type="tech">sh8013</domain:contact>
        <domain:ns>
          <domain:hostObj>ns1.example.com</domain:hostObj>
          <domain:hostObj>ns1.example.net</domain:hostObj>
        </domain:ns>
        <domain:host>ns1.example.com</domain:host>
        <domain:host>ns2.example.com</domain:host>
        <domain:clID>ClientX</domain:clID>
        <domain:crID>ClientY</domain:crID>
        <domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate>
        <domain:upID>ClientX</domain:upID>
        <domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate>
        <domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate>
        <domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate>
        <domain:authInfo>
          <domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6-TRANSFER</domain:pw>
        </domain:authInfo>
      </domain:infData>
    </resData>
    <extension>
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:xml:ns:dkhm-4.0">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
    </extension>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54322-XYZ</svTRID>
    </trID>
  </response>
</epp>
```

Ref: [`info_domain_response_with_authid_extension.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/info_domain_response_with_authid_extension.xml)

The response is extended with the `dkhm:authInfoExDate` extension, communicating the expiration date of the current **AuthInfo** for the domain. Please see the XSD definition below.

<a id="authinfo-token-format"></a>
## AuthInfo Token Format

The **AuthInfo** token is generated by DK Hostmaster and will adhere to the following proposed format:

`<handle>-<unique key>`

E.g.

An **AuthInfo** token set request by DK Hostmaster A/S (`DKHM-1`) for change of registrar (transfer), will resemble the following:

`DKHM1-DK-098f6bcd4621d373cade4e832627b4f6-TRANSFER`

We are still evaluating the generation of the unique key, where we want to base the implementation on a unpredictable, but easily transportable format, either based on GUID, UUID or a checksum.

The requirements are:

- Unpredictable (is secure to the extent possible and for the given TTL time frame)
- Human pronounceable (can be communicated over telephone call)
- Usable (constrained on length and format)

<a id="xsd-definition"></a>
## XSD Definition

This XSD definition is for the proposed extension `dkhm:authInfoExDate`, which is used to enrich the response to the `info domain` request.

```xsd
  <!-- custom: authInfo expiration date -->
  <simpleType name="authInfoExDate">
    <restriction base="dateTime" />
  </simpleType>
```

Example (lifted from above):

```xml
    <extension>
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:xml:ns:dkhm-4.0">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
    </extension>
```

Ref: [`dkhm-4.0.xsd`][DKHMXSD4.0]

The referenced XSD version is not deployed at this time and is only available in the [EPP XSD repository][DKHMXSDSPEC], it might be surpassed by a newer version upon deployment of the EPP service implementing the proposal, please refer to the revision of [EPP Service Specification][DKHMEPPSPEC] describing the implementation.

<a id="references"></a>
## References

1. ["New basis for collaboration between registrars and DK Hostmaster"][CONCEPT]
1. [DK Hostmaster EPP Service Specification][DKHMEPPSPEC]
1. [DK Hostmaster EPP Service XSD Repository][DKHMXSDSPEC]
1. ["DKHM RFC Transfer / Change Registrar"][DKHMRFCTRANSFER]
1. [RFC:5731: "Extensible Provisioning Protocol (EPP) Domain Name Mapping"][RFC:5731]
1. [Wikipedia: AAA](https://en.wikipedia.org/wiki/AAA_(computer_security))

[CONCEPT]: https://www.dk-hostmaster.dk/en/new-basis-collaboration-between-registrars-and-dk-hostmaster
[DKHMEPPSPEC]: https://github.com/DK-Hostmaster/epp-service-specification
[DKHMXSDSPEC]: https://github.com/DK-Hostmaster/epp-xsd-files
[DKHMRFCTRANSFER]: https://github.com/DK-Hostmaster/DKHM-RFC-Transfer
[RFC:5731]: https://www.rfc-editor.org/rfc/rfc5731.html
[DKHMXSD4.0]: https://github.com/DK-Hostmaster/epp-xsd-files/blob/master/dkhm-4.0.xsd
