# CKA Resources

Since I needed to understand k8s architecture for this one, it was time to set up a cluster from scratch using [Linux VMs](k8s/CKAlab.md).

For mine, I followed [FreeCodeCamp](https://www.youtube.com/watch?v=Fr9GqFwl6NM). This series is deprecated so I had to update some things to make it work. 

### [Cloud With VarJosh](https://www.youtube.com/playlist?list=PLmPit9IIdzwRjqD-l_sZBDdPlcSfKqpAt)

Wow, if you're not sure where your k8s gaps are, this is the series you want to eatch! He does an excellent job at tying all the relevant concepts together instead of just throwing them at you like your typical Stack Overflow answer section. 

He is engaging and also gets excited about showing off something he thinks his audience would enjoy. I highly recommend this one!

### Lab Practice

These are resources you can use to drop into a [killercoda playground](https://killercoda.com/playgrounds/scenario/cka) or other local machine. 

- [IT Kiddie](itkiddie.md)
- [DumbItGuy](dumbitguy.md) -- in progress

Planned:
- [simonbbb](https://github.com/simonbbbb/CKA-Hand-on-lab) - This one creates the cluster so killercoda would not be necessary to complete it. 

### Youtube Playlists

For Learning Concepts and general practice:  
- [Cloud With VarJosh](https://www.youtube.com/playlist?list=PLmPit9IIdzwRjqD-l_sZBDdPlcSfKqpAt) - I sung his praises earlier. 

- [DevOpsMasters](https://www.youtube.com/@DevOpsMasters) - Explanations for killer.sh questions. 

Exam-specific advice and guides:  
- [JayDemy](https://www.youtube.com/playlist?list=PLSsEvm2nF_8nGkhMyD1sq-DqjwQq8fAii) - This is usually mentioned a long with IT Kiddie and DumbItGuy but I couldn't find any accompanying labs to go with it so I'll watch it once I'm done with labs. 
- [Atla3](https://www.youtube.com/watch?v=eGv6iPWQKyo) - This covers some gotchas that were added to CKA recently. I'll add notes when I give it a rewatch. 

These are the same creators in the Lab Practice section. 
- [IT Kiddie](https://www.youtube.com/playlist?list=PLkDZsCgo3Isr4NB5cmyqG7OZwYEx5XOjM)
- [DumbItGuy](https://www.youtube.com/playlist?list=PLvZb3tGyqC1TOasSaN36haM5xlCxHQBlA)

### Mock Exams

- [CK-X Simulator](https://github.com/sailor-sh/CK-X/tree/master) - This creates a local lab and had a decent variety of questions. I'm not writing too much on it because a lot of it is deprecated and for novices, you'll likely find this more trouble than its worth. For example, the HPA question required version autoscaling/v1beta.

I like the way the lab simulated the testing environment (similar to killer.sh) and I performed the github labs with it at first. But at some point, not enough worked well enough to stick with it. 

It's open source so I may fork it to upgrade it to make it work more faithfully or add a new set of questions but it will require more time than I have right now. 

---

[back to main](../../README.md)