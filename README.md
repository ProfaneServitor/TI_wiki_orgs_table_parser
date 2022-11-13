# What is this

This is a script to generate orgs table for this page: https://hoodedhorse.com/wiki/Terra_Invicta/Orgs

# System requirements

Ruby 2.7+

# How to use

Place `generate_table.rb` next to `TIOrgTemplate.json` (usually found in `Terra_Invicta/TerraInvicta_Data/StreamingAssets/Templates`) and run:

```bash
ruby generate_table.rb
```

This should generate a table in `output.txt`
