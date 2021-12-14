# Cross Reference to Variant
This repo contains scripts to  **this paragraph needs to be expanded**

* perl script (mn2xref.pl) to:
  * change 2nd & subsequent \mn fields to *\lf SEpR-(E|S-n)\lv* pairs

    * e.g. 

    * ````SFM (MDF)
      \lx atowuhɛ
      ...
      \mn atɔ
      \mn wu 5
      \mn -hɛ
      
      \lx monihɛ
      \mn moni
      \mn -hɛ
      ````
      becomes:

    * ````SFM (MDF)
      \lx atowuhɛ
      ...
      \mn atɔ
      \lf SEpR-S-5
      \lv wu 5
      \lf SEpR-E
      \lv -hɛ
      
      \lx monihɛ
      \mn moni
      \lf SEpR-E
      \lv -hɛ
      ````

  * log the order of the entries

    *  **to be written**

* perl script to modify a FLEx database that has imported the SFM file with the special cross references

  * Adds them to the first (variant) entry/sense

* read the log file and re-order the entries

  * **to be written**




## Notes

The Abbreviation shouldn't appear elsewhere in the database

SFM import needs dummy prefix/suffixes

Manual cleanup of the FLEx database afterwards:

* merge the dummy prefix/suffixes with the pre-existing real ones
* delete the special cross-refs
