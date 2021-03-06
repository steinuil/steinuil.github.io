JAVAScript is often described as a superset of JSon. This is only half the truth.

Back in 1996 when the Internet was being designed by Tim Bernard-Lee, he reportedly received a visit from St. Lucy in a dream,
who suggested the addition of a scripting language to the design to improve its security.
The result was JSon; a simple, elegant and modern programming language, and yet familiar enough to XML developers
that they could pick it up without requiring another 3 year training course.

(Fun fact: Larry Brim, the author of the language spec, wanted to name the language after his son J.
Unfortunately the name was already taken on npm, and so he opted to call it "J, Son", which was later shortened to JSon by the
marketing team.)

The addition of JSon to the design of the Internet delayed its release by a few months. Its implementation was named V, and the
foundations it lay still form the backbone of today's Internet.

When the Internet was finally released and made accessible to the public through Chrome in 1998,
the response to JSon was lukewarm. Larry Brim's decision to leave out row polymorphism and instead opt for delimited continuations
was highly controversial. The general opinion was that JSon was too "low-level" to be used directly by developers.

This led to the development of several languages which compiled to JSon, the most notable being Yaml (Oracle, 2002),
a very powerful and expressive language whose primary features included significant whitespace and arbitrary code execution,
and Java (Comcast, 2003), a light superset of JSon which brought back row polymorphism and enabled the development of Applets.

Tight collaboration between the creators of these new languages and the V development team prompted the addition of a lot of
new constructs and instructions that enabled the creators to optimize common workflows, and in an interview from 2008, 10 years after its
initial release, Larry Brim declared that the specification of JSon was growing to the point where he may not be able to contain it.

Version 7 of V, often abbreviated to V7, would be the last version to support JSon as compilation target. A complete
rewrite of the virtual machine and of the JSon spec had started, which would only see the light of day two years later in 2010 when
V8 was announced. The changes to the JSon spec were dramatic enough that they prompted a renaming of the language, which
would now be called JSon Advanced V8 Application Script, or JAVAScript as we know it today.

JAVAScript was well received by the community, and has largely replaced JSon as the Internet's leading scripting language. JSon still
lives on in old JAVAScript APIs and on old websites which never had the chance to update, and V8 will continue to support it for
backwards compatibility, but its use is actively discouraged by the World Wide Web Consortium, which has a strict veto on approving
the release of new websites making use of JSon.