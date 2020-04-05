![DK Hostmaster Logo](https://www.dk-hostmaster.dk/sites/default/files/dk-logo_0.png)

# DKHM RFC for AuthInfo

![GitHub Workflow build status badge markdownlint](https://github.com/DK-Hostmaster/DKHM-RFC-AuthInfo/workflows/Markdownlint%20Workflow/badge.svg)

## Table of Contents

<!-- MarkdownTOC bracket=round levels="1,2,3,4" indent="  " autolink="true" autoanchor="true" -->

- [Introduction](#introduction)
  - [About this Document](#about-this-document)
  - [XML and XSD Examples](#xml-and-xsd-examples)
- [Description](#description)
  - [Setting and Unsetting the AuthInfo Token](#setting-and-unsetting-the-authinfo-token)
  - [Fetching the AuthInfo via EPP](#fetching-the-authinfo-via-epp)
  - [Name Server Change Request](#name-server-change-request)
  - [Requesting a Name Server Change Using AuthInfo via a Pull Operation](#requesting-a-name-server-change-using-authinfo-via-a-pull-operation)
- [XSD Definition](#xsd-definition)
- [Scenario Matrix](#scenario-matrix)
  - [AuthInfo Token Access](#authinfo-token-access)
  - [Generation of AuthInfo token with Registry](#generation-of-authinfo-token-with-registry)
  - [Change of Name Server, pull \(external and internal\)](#change-of-name-server-pull-external-and-internal)
- [AuthInfo Token Format](#authinfo-token-format)
- [References](#references)

<!-- /MarkdownTOC -->

<a id="introduction"></a>
## Introduction

This is a draft and proposal for a new process for name server changes via the DK Hostmaster EPP, Registrar-portal (RP) and self-service (SB) portals/services using **AuthInfo** (authorization token).

- The goal is to make the **AuthInfo** token mandatory for use in change name server operations
- An active **AuthInfo** token expires if the registrant is changed
- An active **AuthInfo** token expires when a name server change is executed successfully.
- An active **AuthInfo** token expires automatically after 14 days
- Only one **AuthInfo** token is available and active at a given time if any
- No email notifications will be sent out when the change of name server operation is executed
- **AuthInfo** token can be retrieved via the following portals: EPP, RP and SB, by the registrant, admin/proxy or current name service provider
- The change of name server operation can be initiated from the following portals: EPP, RP or SB
- [Anonymous change of name servers](https://www.dk-hostmaster.dk/en/anonymous-change-name-server) and [internal change of name servers via email](https://www.dk-hostmaster.dk/en/internal-change-name-server) will both be decommissioned
- Multi-operation commands for EPP Update Domain will no longer be supported (more details on this below)
- A Name service provider (NSP) can control the flow to own name servers by only supporting _pull_ operations

<a id="about-this-document"></a>
### About this Document

We have adopted the term RFC (_Request For Comments_), due to the recognition in the term and concept, so this document is a process supporting document, aiming to serve the purpose of obtaining a common understanding of the proposed implementation and to foster discussion on the details of the implementation. The final specification will be lifted into the [DK Hostmaster EPP Service Specification](https://github.com/DK-Hostmaster/epp-service-specification) implementation and this document will be closed for comments and the document no longer be updated.

The working title for this initiative was **AuthID**, we have later adopted the term **AuthInfo** and refer to the actual mechanism as **AuthInfo** token for easier mapping with existing and standard EPP RFC terminology. Do note the term **AuthID** might appear in examples, documentation and filenames, this can be exchanged for **AuthInfo** and **AuthInfo** token where appropriate.

The term **external** name server change is between two different name server administrators, which cannot be resolved to have any relation of belonging to the same registrar group in the registry. The term **Internal** name server change is between two name server administrators, which can be resolved to have a relation of belonging to the same registrar group with the registry.

The term NSP is use to describe the name server administrator (NSA) and registrar users with the similar role in a registrar group.

<a id="xml-and-xsd-examples"></a>
### XML and XSD Examples

All example XML files are available in the [DK Hostmaster EPP XSD repository](https://github.com/DK-Hostmaster/epp-xsd-files) in the [auth_id branch](https://github.com/DK-Hostmaster/epp-xsd-files/tree/auth_id).

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

**AuthInfo** is only present in the `change` sub-command (see: [RFC:5731 Section 3.2.5](https://tools.ietf.org/html/rfc5731#page-25)). It is however not possible to indicate what sub-command the **AuthInfo** is designated for and due to the privilege and functionality mapping between operations and sub-commands, this makes it impossible to clearly indicate the scope of the authorization.

In order to implement secure handling, which also ensures the best integrity and least complexity it is proposed to only support a single operation per `update domain` request. This allows for the addition and removal of name servers to be performed together, but all of the listed sub-commands have to be requested on an per request basis and cannot be bundled.

![diagram update domain process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/epp_update_domain-v2.0.png)

Currently the **AuthInfo** mechanism is only supporting the change of name servers operation (`add host` and `remove host`) for a given domain name, but since a general interface for a generic command as `update domain` it is important to make the protocol usage pattern extensible so possible future adoption in the use of **AuthInfo** authorization can be implemented without breaking backwards compatibility to the extent possible. The constraint of one operation per request honors this requirement.

Only one active **AuthInfo** token is allowed at a given time, if an **AuthInfo** token is unset or expires, no **AuthInfo** is defined and hence will change of name servers not be supported for the given domain name.

<a id="setting-and-unsetting-the-authinfo-token"></a>
### Setting and Unsetting the AuthInfo Token

Setting the **AuthInfo** is as described above also expected to be handled by the `update domain` command, since this is the sole command working on the domain object in general.

Setting the **AuthInfo** via EPP is expected to be accomplished using the following example, where the keyword `auto` indicates and hence initiates the generation of a new **AuthInfo** token.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:chg>
          <domain:authInfo>
            <domain:pw>auto</domain:pw>
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

When the **AuthInfo** token has been set it can be retrieved via the EPP command: `info domain` or via similar detailed information points in the RP or SB portals, due note that the retrieval requires authorization and therefor authentication and controlled access (AAA).

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
          <domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</domain:pw>
        </domain:authInfo>
      </domain:infData>
    </resData>
    <extension>
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:xml:ns:dkhm-3.1">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
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

<a id="name-server-change-request"></a>
### Name Server Change Request

For the actual use of the **AuthInfo**, the following use-cases have been identified:

- Requesting a Name Server Change Using AuthInfo via a Pull Operation

<a id="requesting-a-name-server-change-using-authinfo-via-a-pull-operation"></a>
### Requesting a Name Server Change Using AuthInfo via a Pull Operation

Request name server change is based on an operation, where the initiator is the registrant, The registrant obtains the **AuthInfo** token from the registry or the existing NSP. The **AuthInfo** token is communicated to the new NSP, who then initiates the requests for change of name server operation hence it _pulls_ from the existing NSP,

The **AuthInfo** can be transported _out-of-band_.

![process diagram change name server using NSP authinfo process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/change_name_server_using_nsp_auth-id_process-v2.0.png)

:point_right: In most browsers it is possible to open the image in another tab to see an enlarged version.

All actual change of name servers has to go via the registry and the existing infrastructure in place to support these requests and operations.

The request for completing the change of name server via EPP (GUI availability via SB and RP would of course have to support transporting similar parameters).

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:add>
          <domain:ns>
            <domain:hostObj>ns2.example.com</domain:hostObj>
          </domain:ns>
        </domain:add>
        <domain:rem>
          <domain:ns>
            <domain:hostObj>ns1.example.com</domain:hostObj>
          </domain:ns>
        </domain:rem>
        <domain:chg>
          <domain:authInfo>
            <domain:pw>DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</domain:pw>
          </domain:authInfo>
        </domain:chg>
      </domain:update>
    </update>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`update_domain_change_name_server_with_authid.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/update_domain_change_name_server_with_authid.xml)

1. This implementation can be contained to the standard EPP specification
1. This implementation sets a requirement for a recommended use, for a single operation per request, in order to handle the **AuthInfo** correctly in the AAA layer of the EPP Service application (See: References).

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
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:xml:ns:dkhm-3.1">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
    </extension>
```

Ref: [`dkhm-3.1.xsd`](https://raw.githubusercontent.com/DK-Hostmaster/epp-xsd-files/master/dkhm-3.1.xsd)

:warning: The reference and file mentioned above is not released at this time, so this file might be re-versioned upon release.

<a id="scenario-matrix"></a>
## Scenario Matrix

These matrices aims to describe the outcome of different scenarios based on the relevant parameters.

Do note the matrix does not take the following scenarios into account.

- DNS server does not respond to relevant DNS query
- Domain and name server state

These parameters are evaluated at run time and for the sake of communication and brevity they are not factored into the scenarios below. The descriptions assume that both name server and domain states are eligible for change of name servers for the domain in question.

<a id="authinfo-token-access"></a>
### AuthInfo Token Access

| Operation                    | Existing NSP | Registrant and Admin/Proxy | New NSP |
| :--------------------------- | :----------: | :------------------------: | :-----: |
| Can set **AuthInfo** token   | X            | X                          |         |
| Can unset **AuthInfo** token | X            | X                          |         |
| Can view **AuthInfo** token  | X            | X                          | X (1)   |

1) Can see if Registrant or Admin/Proxy has initiated request for change of name server, please see below: "Generation of AuthInfo token with Registry".

<a id="generation-of-authinfo-token-with-registry"></a>
### Generation of AuthInfo token with Registry

| Scenario               | Outcome            |
| :--------------------- | ------------------ |
| Existing NSP generates | AuthInfo token (1) |
| New NSP initiates      | Error              |
| Admin/proxy generates  | AuthInfo token (2) |

1) The **AuthInfo** token is made visible to the existing NSP, registrant and admin/proxy
2) The **AuthInfo** token is made visible to the new NSP (recipient) and existing NSP, registrant and admin/proxy. The new NSP can then initiate the change of name servers request (_pull_).

<a id="change-of-name-server-pull-external-and-internal"></a>
### Change of Name Server, pull (external and internal)

| Scenario                                | AuthInfo Token provided | Outcome           |
| :-------------------------------------- | :---------------------: | ----------------- |
| New NSP initiates change of name server | X                       | Change successful |
| New NSP initiates change of name server |                         | Error             |

<a id="authinfo-token-format"></a>
## AuthInfo Token Format

The **AuthInfo** token is generated by DK Hostmaster and will adhere to the following proposed format:

`<handle>-<unique key>`

E.g.

An **AuthInfo** token set request by DK Hostmaster A/S (`DKHM-1`), will resemble the following:

`DKHM1-DK-098f6bcd4621d373cade4e832627b4f6`

We are still evaluating the generation of the unique key, where we want to base the implementation on a unpredictable, but easily transportable format, either based on GUID, UUID or a checksum.

The requirements are:

- Unpredictable (is secure to the extent possible and for the given TTL time frame)
- Human pronounceable (can be communicated over telephone call)
- Usable (constrained on length and format)

<a id="references"></a>
## References

- [DK Hostmaster EPP Service Specification](https://github.com/DK-Hostmaster/epp-service-specification)
- [DK Hostmaster EPP Service XSD Repository](https://github.com/DK-Hostmaster/epp-xsd-files)
- [RFC:5731: Extensible Provisioning Protocol (EPP) Domain Name Mapping](https://tools.ietf.org/html/rfc5731)
- [Wikipedia: AAA](https://en.wikipedia.org/wiki/AAA_(computer_security))
