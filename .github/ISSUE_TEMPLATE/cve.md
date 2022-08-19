---
name: CVE
about: Notify and Handle Vulnerabilities
title: ''
labels: cve
assignees: ''
---
## Report

This section to be completed to report a potential vulnerability.

**Describe**

Add a description about the potential vulnerability.

**References**

Add other references that might be required to help understand the potential vulnerability. 


## Handling 

If you are reporting a potential vulnerability, you could ignore this section. It is intended to be managed by 
a [Vulnerability Manager](https://docs.google.com/document/d/15vsta8H4gXQkpSjRVTQH1o3KrwgOY5H4c8ydNgrHt-I)

- [ ] Reporter notifies Weaveworks team (Receiver) about a potential vulnerability via any of the Security Vulnerability Sources. Receiver acknowledges it. If likely to be a legitimate request,  Receiver creates a private issue of type CVE in https://github.com/weaveworks/weave-gitops-private to start the formal intake.
- [ ] Vulnerability Manager triages the request to either accept or rejects it:
- [ ] In case of accepted, Vulnerability Manager starts the  coordination of the vulnerability based on the created issue. The vulnerability is treated as highest priority and directed to the respective Product  Team.
- [ ] In case of rejected, if needed, a response to Reporter is provided about the rejection and the process terminates.
- [ ] Product Team evaluates the vulnerability with help from Vulnerability Manager. The evaluation should include which products and versions are affected.
- [ ] If the vulnerability does not pose a threat to the product or service, Vulnerability Manager responds back to the Reporter with proper reasoning.
- [ ] If the reported request is considered a vulnerability, Vulnerability Manager responds back to the Reporter, accepting the issue. Vulnerability Manager communicates and coordinates to the rest of internal stakeholders. Vulnerability Manager engages with CX to start the discovery of customers being affected.
- [ ] Product team provides a workaround, Vulnerability Manager makes it available to the Reporter and notifies CX. CX manages with customers the workaround.
- [ ] Product Team works to identify a fix and produce a time estimation (ETA) to create the fix for the product or service.
- [ ] Vulnerability Manager adds a 4 weeks buffer to the ETA. This date becomes the public announcement date.
- [ ] Vulnerability Manager e notifies the Reporter of the  public announcement date. Vulnerability Manager asks the Reporter if they want to be credited. A Public Security Advisory will be issued accordingly.  
- [ ] Vulnerability Manager creates a Private Security Advisory for the vulnerability, including the impact, and any available mitigations. It would be created using this template. An example of a Security Advisory is CVE-1126.
- [ ] CX would announce with customers the vulnerability sharing the Security Advisory.
- [ ] Product Team delivers the fix and communicates to Vulnerability Manager. Vulnerability Manager provides it to the Reporter and all affected customers via CX. CX manages the application of the fix on the customer side.
- [ ] A Public Security Advisory will be issued after all the fixes are issued to the customers and the public announcement date has been reached.
