# Cross-reference to Variant (Xref2Var)
FLEx (as of version 9.1) has a bug in the import process when a complex form/subentry is imported. The first main entry (component) reference is handled &ndash; see the Var2Compform portion of the Subentry Promotion for details. However, the 2nd, 3rd, ... nth references are ignored and those links are lost. The scripts included here provide a way to provide references to multiple main entries.

### How these scripts work

There are two main Perl scripts used in this process **mn2xref.pl**, and **Xref2Var.pl**. The first, **mn2xref.pl**, modifies the SFM file to prepare it for import into FLEx. The second, **Xref2Var.pl**, modifies the FLEx project after the SFM file has been imported.

The **mn2xref.pl** script modifies the SFM file to change the 2nd ... nth component references to  special cross-references. The  **Xref2Var.pl** script modifies the FLEx project. It changes the special cross-refence into variants with special characteristics.

The variants that are created in the FLEx project by **Xref2Var.pl** can be changed to complex forms by running the **Var2Compform** script of the **Subentry Promotion** repo.

### Two problems addressed by these scripts

1) When complex forms  are created manually within FLEx (i.e. not imported), it creates an ordered list of the components within the record of the Complex form entry. Cross-references are not stored in order.  The **mn2xref.pl** script that creates the cross-references includes a component number within the cross-reference type name. After the SFM file is imported, the **Xref2Var.pl**  script that converts the cross-references to variant links processes the cross-references in order so that the newly created variant links are in order.
2) Another bug occurs when FLEx imports an SFM file into a project that already has entries. It doesn't keep track of sense numbers of entries that already exist in the project. This means that when a new SFM record has a reference to one of the senses of a pre-existing entry, it doesn't handle it properly. The **mn2xref.pl** script handle this problem by including the sense number in the cross reference. The  **Xref2Var.pl**  script finds the proper sense based on that number. The variant reference that it creates will to point to the proper sense.

### Preparing the SFM file

* *This section needs more detail.*

* Include complex form marker in the records when you create them.

* The component references should not be under a sense. I.e., they should appear before any \\ps,  \\sn,  \\ge or  \\de markers

* run perl script **mn2xref.pl** to:
  * change 2nd & subsequent \mn fields to either *\lf EntryComponent-<component#>\lv target* or r *\lf SenseComponent-<sense#>-<component#>\lv target*  pairs.

    * e.g. from the Nkonya Language of Ghana (English is in  parentheses)

    * ````SFM (MDF)
      \lx atowuhɛ (something dead)
      ...
      \mn atɔ (something)
      \mn wu 1 (die)
      \mn -hɛ (Adjectivizer)
      
      \lx monihɛ (large)
      \mn moni (grow large)
      \mn -hɛ (Adjectivizer)
      ````
      becomes:

    * ````SFM (MDF)
      \lx atowuhɛ
      ...
      \mn atɔ
      \lf SenseComponent-1-2 (sense #1 of wu is the 2nd component of atowuhɛ)
      \lv wu
      \lf EntryComponent-3 ( -hɛ is 3rd component of atowuhɛ)
      \lv -hɛ
      
      \lx monihɛ
      \mn moni
      \lf EntryComponent-2 ( -hɛ is 2nd component of monihɛ)
      \lv -hɛ
      ````

*  **Xref2Var.pl**  perl script to modify a FLEx database that has imported the SFM file with the special cross-references

  * sorts the cross references into component order
  * Adds them to the first (variant) entry
  * If a cross-reference is to a sense, it finds the sense and makes the component a sense reference


### Steps to this Process

There are seven steps (XRC1-7) to this process:

- XRC1. Modify the FLEx database to have fancy unidirectional Complex to Component crossref type.

- XRC2. Add components to complex entries. If the entry is a sub-entry to be promoted don't add the main entry that it is under. The sub-entry promotion process will set that field.
- XRC3. After the **runse2lx.sh**, insert \spec fields for records that have \mn fields without \spec markers. This can be as simple as:

   ```bash
   perl -pf opl.pl in.sfm |\
   perl -pE 's/(\\mn[^#]*#)/$1\\spec _UNSPECIFIED_#/ if (! /\\spec /)' |\
   perl -pf de_opl.pl >out.sfm
   ```

- XRC4. Run **mn2xref.pl** to change 2nd & subsequent \mn marks to fancy \lf markers.
- XRC5. Import the SFM file.
- XRC6. Run the **Xrf2Var.pl** to change the crossrefs to variants.
- XRC7. Delete Complex/Component crossref type from the database.

### How this Process Fits in with the PromoteSubentry Process

There are 6 steps (PS1-6) of the PromoteSubentry Process. The above steps have been interspersed:

- XRC1. Modify the FLEx database to have a unidirectional Complex to Component crossref types.

- PS1. Import  *ModelEntries-MDFroot.db*  into Initial FLEx database to set up Model Subentries.

- XRC2. Add components to complex entries. See note above.

- PS2. Run **runse2lx.sh** subentry extraction and promotion.

- XRC3. Ensure all the component entries are flagged with a component type.

- XRC4. Modify the import mapping so that *mnx* markers are mapped to the new crossref type.

- PS3/XRC5. Import SFM file with Subentries.

- PS4. Run **runVar2Compform.sh** to make the subentries into complex forms

- PS5. Delete the  *"SubEntry Type Flag"* & Model Entries.

- XRC6. Run the **Xrf2Cmpnt.pl** to add the crossrefs as components.

- XRC7. Delete Complex/Component crossref types from the database.

- PS6. Delete the Model Complex form template entries

## Notes


The Abbreviation shouldn't appear elsewhere in the LexRefTypes

The script **mn2xref.pl** currently just flags complex form SFM records with no \spec field. Perhaps it should supply the \_UNSPECIFIED\_ marker. Probably sufficient to just set it as a variable, but you could read it from the **PromoteSubentries.ini** file if you want to get fancy.

SFM import needs dummy prefix/suffixes -- maybe not

Manual cleanup of the FLEx database afterwards:

* merge the dummy prefix/suffixes with the pre-existing real ones -- maybe not
* delete the special cross-refs

#### About this Document

This document is written in Markdown format. It's hosted on *github.com*. The github site that it's hosted on will display it in a formatted version.

If you're looking at it another way and you're seeing unformatted text, there are good Markdown editors available for a Windows and Linux. An free on-line editor is available at https://stackedit.io/
