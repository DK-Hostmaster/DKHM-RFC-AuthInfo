![DK Hostmaster Logo](https://www.dk-hostmaster.dk/sites/default/files/dk-logo_0.png)

# DKHM RFC for AuthInfo

## Table of Contents

<!-- MarkdownTOC bracket=round levels="1,2,3,4" indent="  " -->

- Introduction
  - About this Document
  - XML and XSD Examples
- Description
  - Setting and Unsetting the AuthInfo Token
  - Fetching the AuthInfo via EPP
  - Name Server Change Request
  - Requesting a Name Server Change Using AuthInfo via a Pull Operation
- XSD Definition
- Scenario Matrix
  - AuthInfo Token Access
  - Generation of AuthInfo token with Registry
  - Change of Name Server, pull \(external\)
  - Change of Name Server, push \(external\)
  - Change of Name Server, push or pull \(internal\)
- AuthInfo Token Format
- References

<!-- /MarkdownTOC -->

## Introduction

This is a draft and proposal for an extension to handle **AuthInfo** (authorization token) for name server changes via the DK Hostmaster EPP, Registrar-portal (RP) and self-service (SB) portals/services.

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

### About this Document

We have adopted the term RFC (_Request For Comments_), due to the recognition in the term and concept, so this document is a process supporting document, aiming to serve the purpose of obtaining a common understanding of the proposed implementation and to foster discussion on the details of the implementation. The final specification will be lifted into the [DK Hostmaster EPP Service Specification](https://github.com/DK-Hostmaster/epp-service-specification) implementation and this document will be closed for comments and the document no longer be updated.

The working title for this initiative was **AuthID**, we have later adopted the term **AuthInfo** and refer to the actual mechanism as **AuthInfo** token for easier mapping with existing and standard EPP RFC terminology. Do note the term **AuthID** might appear in examples, documentation and filenames, this can be exchanged for **AuthInfo** and **AuthInfo** token where appropriate.

The term **external** name server change is between two different name server administrators, which cannot be resolved to have any relation of belonging to the same registrar group in the registry. The term **Internal** name server change is between two name server administrators, which can be resolved to have a relation of belonging to the same registrar group with the registry.

### XML and XSD Examples

All example XML files are available in the [DK Hostmaster EPP XSD repository](https://github.com/DK-Hostmaster/epp-xsd-files) in the [auth_id branch](https://github.com/DK-Hostmaster/epp-xsd-files/tree/auth_id).

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

### Setting and Unsetting the AuthInfo Token

Setting the **AuthInfo** is as described above also expected to be handled by the `update domain` command, since this is the sole command working on the domain object in general.

Setting the **AuthInfo** via EPP is expected to be accomplished using the following example, where the keyword `AUTO` indicates and hence initiates the generation of a new **AuthInfo** token.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
  <command>
    <update>
      <domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
        <domain:name>example.com</domain:name>
        <domain:chg>
          <domain:authInfo>
            <domain:pw>AUTO</domain:pw>
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
            <domain:pw></domain:pw>
          </domain:authInfo>
        </domain:chg>
      </domain:update>
    </update>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`update_domain_unset_authid.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/update_domain_unset_authid.xml)

The command simply unsets (_removes/clears_) an **AuthInfo** token if it exists.

1 This implementation can be contained to the standard EPP specification
1 The operation is not particularly explicit about what it does

![diagram unset auth-id process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/unset_auth-id_proces-2.0.png)

Generally the two operations will support the following use-cases:

- `set` will let the requester request the generation of an **AuthInfo** token for the given domain
- and `unset` will let the requester invalidate a previously set **AuthInfo** token for the given domain

:wrench: a clarification is required if an error/warning should be emitted if no **AuthInfo** token is deleted.

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
      <dkhm:authInfoExDate xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.6">2018-11-14T09:00:00.0Z</dkhm:authInfoExDate>
    </extension>
    <trID>
      <clTRID>ABC-12345</clTRID>
      <svTRID>54322-XYZ</svTRID>
    </trID>
  </response>
</epp>
```

Ref: [`info_domain_response_with_authid_extension.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/info_domain_response_with_authid_extension.xml)

The response is extended with the `dkhm:authIdExDate` extension, communicating the expiration date of the current **AuthInfo** for the domain. Please see the XSD definition below.

### Name Server Change Request

For the actual use of the **AuthInfo**, the following use-cases have been identified:

- Requesting a Name Server Change Using AuthInfo via a Pull Operation
- Requesting a Name Server Change via a Push Operation

### Requesting a Name Server Change Using AuthInfo via a Pull Operation

Request name server change is based on an operation, where the initiator is the registrant, The registrant obtains the **AuthInfo** token from the registry or the existing NSP. The **AuthInfo** token is communicated to the new NSP, who then initiates the requests for change of name server operation hence it _pulls_ from the existing NSP,

The **AuthInfo** can be transported _out-of-band_.

![process diagram change name server using NSP authinfo process v2.0](https://github.com/DK-Hostmaster/epp-service-specification/blob/master/images/change_name_server_using_nsp_auth-id_process-v2.0.png)

:point_right: In most browsers it is possible to open the image in another tab to see an enlarged version.

All actual change of name servers has to go via the registry and the existing infrastructure in place to support these requests and operations.

The request for completing the change of name server via EPP (GUI availability via SB and RP would of course have to support transporting similar parameters).

The only operation where a _push_ is supported is when the existing and new registrar can be resolved to be the same registrar group, so the initiator can be either of the two since they both hold the privilege to execute the operation, this is what is referred to as an internal change of name server operation.

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
      </domain:update>
    </update>
    <extension>
      <dkhm:authInfo xmlns:dkhm="urn:dkhm:params:xml:ns:dkhm-2.6">DKHM1-DK-098f6bcd4621d373cade4e832627b4f6</dkhm:authInfo>
    </extension>
    <clTRID>ABC-12345</clTRID>
  </command>
</epp>
```

Ref: [`update_domain_change_name_server_with_authid_extension.xml`](https://github.com/DK-Hostmaster/epp-xsd-files/blob/auth_id/xml/update_domain_change_name_server_with_authid_extension.xml)

1 This implementation cannot be contained to the standard EPP specification, but relies on an extension
1 This implementation might set a requirement for a constraint for a single operation per request, in order to handle the **AuthInfo** correctly in the AAA layer of the EPP Service application (See: References).

Alternatively the use of an extension could be avoided by using the existing `domain:authInfo` field, which is also used to handle the **AuthInfo** token.

The issue with this approach however is the potential conflict for identification and mapping between the **AuthInfo** authorisation. For the first implementation only the change of nameserver operation is in scope, but if change of registrant is also opened for support via **AuthInfo** the token is no longer unambigous.

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

1 This implementation can be contained to the standard EPP specification
1 This implementation might set a requirement for a constraint for a single operation per request, in order to handle the **AuthInfo** correctly in the AAA layer of the EPP Service application (See: References).

## XSD Definition

This XSD definition is for the proposed extension `dkhm:authIdExDate`.

```xml
  <!-- custom: authInfo token  -->
  <simpleType name="authInfoToken">
    <restriction base="token" />
  </simpleType>

  <!-- custom: authInfo expiration date -->
  <simpleType name="authInfoExDate">
    <restriction base="dateTime" />
  </simpleType>
```

Ref: [`dkhm-2.6.xsd`](https://raw.githubusercontent.com/DK-Hostmaster/epp-xsd-files/auth_id/dkhm-2.6.xsd)

:warning: The reference and file mentioned above is not similar to the 2.6 version available in production, so this file will be re-versioned upon release.

## Scenario Matrix

These matrixes aims to describe the outcome of different scenarios based on the relevant parameters.

Do note the matrix does not take the following scenarios into account.

- DNS server does not respond to relevant DNS query
- Domain and name server state

These parameters are evaluated at run time and for the sake of communication and brevity they are not factored into the scenarios below. The descriptions assume that both name server and domain states are eligible for change of name servers for the domain in question.

### AuthInfo Token Access

| Operation                    | Existing NSP | Registrant and Admin/Proxy | New NSP |
| :--------------------------- | :----------: | :------------------------: | :-----: |
| Can set **AuthInfo** token   | X            | X                          |         |
| Can unset **AuthInfo** token | X            | X                          |         |
| Can view **AuthInfo** token  | X            | X                          | X (1)   |

1) Can see if Registrant or Admin/Proxy has initiated request for change of name server, please see below: "Generation of AuthInfo token with Registry".

### Generation of AuthInfo token with Registry

| Scenario               | Outcome            |
| :--------------------- | ------------------ |
| Existing NSP generates | AuthInfo token (1) |
| New NSP initiates      | Error              |
| Admin/proxy generates  | AuthInfo token (2) |

1) The **AuthInfo** token is made visible to the existing NSP, registrant and admin/proxy
2) The **AuthInfo** token is made visible to the new NSP (recipient) and existing NSP, registrant and admin/proxy. The new NSP can then initiate the change of name servers request (_pull_).

### Change of Name Server, pull (external)

| Scenario                                | AuthInfo Token provided | Outcome           |
| :-------------------------------------- | :---------------------: | ----------------- |
| New NSP initiates change of name server | X                       | Change successful |
| New NSP initiates change of name server |                         | Error             |

### Change of Name Server, push (external)

| Scenario                                     |  AuthInfo Token provided | Outcome |
| :------------------------------------------- | :----------------------: | ------- |
| Existing NSP initiates change of name server | X                        | Error   |
| Existing NSP initiates change of name server |                          | Error   |

### Change of Name Server, push or pull (internal)

| Scenario                                     | AuthInfo Token provided | Outcome           |
| :------------------------------------------- | :---------------------: | ----------------- |
| Existing NSP initiates change of name server | X                       | Change successful |
| Existing NSP initiates change of name server |                         | Error             |

## AuthInfo Token Format

The **AuthInfo** token is generated by DK Hostmaster and will adhere to the following proposed format:

`<handle>-<unique key>`

E.g.

An **AuthInfo** token set request by DK Hostmaster A/S (`DKHM-1`), will resemble the following:

`DKHM1-DK-098f6bcd4621d373cade4e832627b4f6`

We are still evaluating the generation of the unique key, where we want to base the implementation on a unpredictable, but easily transportable format, either based on GUID, UUID or a checksum.

The requirements are:

- Unpredictable (is secure to the extent possible and for the given TTL timeframe)
- Speakable (can be spoken over phone)
- Usable (constrained on length and format)

### Alternative proposal

An alternative format could be containing the relevant domain name instead of the handle pointing to the creator, since the creator is not necessarily important, especially in the use-case where you are handling several tokens for several domain names in parallel.

Format:

`eksempel-dk-098f6bcd4621d373cade4e832627b4f6`

And with IDN support (`æøåöäüé.dk`):

`xn--4cabco7dk5a-dk-098f6bcd4621d373cade4e832627b4f6`

## References

- [DK Hostmaster EPP Service Specification](https://github.com/DK-Hostmaster/epp-service-specification)
- [DK Hostmaster EPP Service XSD Repository](https://github.com/DK-Hostmaster/epp-xsd-files)
- [RFC:5731: Extensible Provisioning Protocol (EPP) Domain Name Mapping](https://tools.ietf.org/html/rfc5731)
- [Wikipedia: AAA](https://en.wikipedia.org/wiki/AAA_(computer_security))
