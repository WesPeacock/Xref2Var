# Cross-reference to Variant
FLEx (as of version 9.1) has a bug in the import process when a complex form/subentry is imported. The first main entry (component) reference is handled &ndash; see the Var2Compform portion of the Subentry Promotion for details. However, the 2nd, 3rd, ... nth references are ignored and those links are lost. The scripts included here provide a way to provide references to multiple main entries.

### How these scripts work

There are two main perl scripts used in this process **mn2xref.pl**, and **Xref2Var.pl**. The first, **mn2xref.pl**, modifies the SFM file to prepare it for import into FLEx. The second modifies FLEx project after

The **mn2xref.pl** script modifies the SFM file to change the 2nd ... nth component references to  special cross-references. The  **Xref2Var.pl** script that modifies the FLEx project uses a cross-refence marker that encodes information about the component it refers to.

### Two Problems

1) When complex forms  are created manually within FLEx (i.e. not imported), it creates an ordered list of the components within the record of the Complex form entry. Cross-references are not stored in order.  The **mn2xref.pl** script that creates the cross-references includes a component number within the cross-reference type name. After the SFM file is imported, the **Xref2Var.pl**  script that converts the cross-references to variant links processes the cross-references in order so that the newly created variant links are in order.
2) When FLEx imports an SFM file into a project that already has entries, it doesn't keep track of sense numbers of entries that already exist in the project. This means that when a new SFM record has a reference to a sense of a pre-existing entry, it doesn't handle it properly. The **mn2xref.pl** script handle this problem by including the sense number in the cross reference. The  **Xref2Var.pl**  script finds the proper sense based on that number when it changes the variant reference to point to the proper sense.

### Preparing the SFM file

* Include complex form marker in the records when you create them.
* The component references should not be under a sense. I.e., they should appear before any \\ps,  \\sn,  \\ge or  \\de markers

* perl script (mn2xref.pl) to:
  * change 2nd & subsequent \mn fields to either *\lf EntryComponent-<component#>\lv target* or r *\lf SenseComponent-<sense#>-<component#>\lv target*  pairs.

    * e.g. from the Nkonya Language of Ghana (English is  parentheses)

    * ````SFM (MDF)
      \lx atowuhɛ (something dead)
      ...
      \mn atɔ (something)
      \mn wu 1 (dead)
      \mn -hɛ (Adjectivizer)
      
      \lx monihɛ (large)
      \mn moni (grow large)
      \mn -hɛ (Adjectivizetr)
      ````
      becomes:

    * ````SFM (MDF)
      \lx atowuhɛ
      ...
      \mn atɔ
      \lf SenseComponent-1-2 (sense #1 of atɔ is the 2nd component)
      \lv wu 5
      \lf EntryComponent-3 ( -hɛ is 3rd component)
      \lv -hɛ
      
      \lx monihɛ
      \mn moni
      \lf EntryComponent-2 ( moni is 2nd component)
      \lv -hɛ
      ````

*  **Xref2Var.pl**  perl script to modify a FLEx database that has imported the SFM file with the special cross-references

  * sorts the cross references into component order
  * Adds them to the first (variant) entry
  * If a cross-reference is to a sense, it finds the sense and makes the component a sense reference




## Notes

The Abbreviation shouldn't appear elsewhere in the LexRefTypes

SFM import needs dummy prefix/suffixes -- maybe not

Manual cleanup of the FLEx database afterwards:

* merge the dummy prefix/suffixes with the pre-existing real ones -- maybe not
* delete the special cross-refs
