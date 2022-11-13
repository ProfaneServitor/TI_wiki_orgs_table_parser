require 'json'

def generate_table(input: "TIOrgTemplate.json", output: "output.txt")
  file = File.read(input)
  orgs = JSON.parse(file)
  # Remove randomized orgs
  orgs.reject! { |org| org['randomized'] }
  # Remove faction unique orgs
  orgs.reject! { |org| faction_unique?(org) }
  header = "{| class=\"wikitable sortable mw-collapsible\"
|+ Orgs
|-
! Organization
! tier
! Monthly income
! Councilor attributes
! Missions gained
! Cost
! Required region
! Government?
! Criminal?
! Sociopath?
! Banned
|-"
  footer = '|}'
  rowbreak = "\n|-\n"
  rows = orgs.map { |org| org_to_row(org) }
  table = [header, rows, footer].join(rowbreak)
  # p table
  File.open(output, "w+") do |f|
    f.write(table)
  end
end

def icon(org)
  "[[File:Org #{org['iconResource'].sub('orglogos/', '')}.png|50px]]"
end

def org_to_row(org)
  """
| #{icon(org)} #{org['friendlyName']}
| #{org['tier']}
|
#{income(org)}
|
#{attribs(org)}
|
#{missions(org)}
|
#{cost(org)}
| #{org['homeRegionNames'][0] if org['requiresNationality']}
| #{government?(org)}
| #{criminal?(org)}
| #{sociopath?(org)}
|
#{restricted(org)}
""".strip()
end

def diapason(chance: 100, base: 0, increase: 0)
  '''
    Most bonuses here seem to be expressed in three vars:
      chance to have this bonus at all (in percents)
      base income, if it exists
      random increase, which is maximum number that can be added to base income

    This function takes in these variables and returns human-readable diapason
  '''
  chance < 100 ? lower = 0 : lower = base

  if increase.to_f > 0
    higher = base + increase
  else
    higher = base
  end

  if higher == lower
    return higher.to_s
  end
  return "#{lower}-#{higher}"
end

def income(org)
  'Org income'
  fields = {
    money: ['chanceIncomeMoney', 'incomeMoney', 'randIncomeMoney'],
    influence: ['chanceIncomeInfluence', 'incomeInfluence', 'randIncomeInfluence'],
    ops: ['chanceIncomeOps', 'incomeOps', 'randIncomeOps'],
    boost: ['chanceIncomeBoost', 'incomeBoost', 'randIncomeBoost'],
    mc: ['chanceIncomeMissionControl', 'incomeMissionControl', 'randIncomeMissionControl'],
    research: ['chanceIncomeResearch', 'incomeResearch', 'randIncomeResearch'],
    economy: ['chanceEconomyBonus', 'economyBonus', 'randEconomyBonus'],
    welfare: ['chanceWelfareBonus', 'welfareBonus', 'randWelfareBonus'],
    knowledge: ['chanceKnowledgeBonus', 'knowledgeBonus', 'randKnowledgeBonus'],
    unity: ['chanceUnityBonus', 'unityBonus', 'randUnityBonus'],
    military: ['chanceMilitaryBonus', 'militaryBonus', 'randMilitaryBonus'],
    spoils: ['chanceSpoilsBonus', 'spoilsBonus', 'randSpoilsBonus'],
    mc_priority: ['chanceSpaceDevBonus', 'spaceDevBonus', 'randSpaceDevBonus'],
    space_program: ['chanceSpaceflightBonus', 'spaceflightBonus', 'randSpaceflightBonus'],
  }
  str = ""
  fields.each do |key, categories|
    if !org[categories[1]]
      next
    end
    str << "* #{diapason(chance: org[categories[0]], base: org[categories[1]], increase: org[categories[2]])} #{key}\n"
  end
  # tech
  org['techBonuses'].each do |tb|
    if tb['bonus']
      str << "* #{tb['bonus'] * 100}% #{tb['category']}\n"
    end
  end
  # mining
  if org['miningBonus']
    str << "* #{(diapason(base: org['miningBonus'], increase: org['randMiningBonus']).to_f * 100).round(2)}% mining\n"
  end
  # xp
  if !org['XPModifier'].empty?
    str << "* #{org['XPModifier']} xp\n"
  end
  # engineering projects
  str << "* #{org['projectsGranted']} <span style='background: black;'>[[File:ICO projects.png|20px]]</span> project(s)\n" if org['projectsGranted']

  return str.strip()
end

def attribs(org)
  'Councilor attributes'
  fields = {
    PER: ['chancePersuasion', 'persuasion', 'randPersuasion'],
    INV: ['chanceInvestigation', 'investigation', 'randInvestigation'],
    ESP: ['chanceEspionage', 'espionage', 'randEspionage'],
    CMD: ['chanceCommand', 'command', 'randCommand'],
    ADM: ['chanceAdministration', 'administration', 'randAdministration'],
    SCI: ['chanceScience', 'science', 'randScience'],
    SEC: ['chanceSecurity', 'security', 'randSecurity'],
  }
  str = "\n"
  fields.each do |key, categories|
    if !org[categories[0]]
      next
    end
    str << "* #{diapason(chance: org[categories[0]], base: org[categories[1]], increase: org[categories[2]])} #{key}\n"
  end
  return str.strip()
end

def missions(org)
  org['missionsGrantedNames'].select { |m| m.length > 2 }.map { |m| "* #{m}" }.join("\n")
end

def cost(org)
  'Org cost'
  fields = {
    money: ['costMoney', 'randCostMoney'],
    influence: ['costInfluence', 'randCostInfluence'],
    ops: ['costOps', 'randCostOps'],
    boost: ['costBoost', 'randCostBoost'],
  }
  str = ""
  fields.each do |key, categories|
    if !org[categories[0]]
      next
    end
    str << "* #{diapason(base: org[categories[0]], increase: org[categories[1]])} #{key}\n"
  end
  return str.strip()
end

def government?(org)
  return true if org['requiredOwnerTraits'].include?('Government')
  return false if org['prohibitedOwnerTraits'].include?('Government')
end

def criminal?(org)
  return true if org['requiredOwnerTraits'].include?('Criminal')
  return false if org['prohibitedOwnerTraits'].include?('Criminal')
end

def sociopath?(org)
  return true if org['requiredOwnerTraits'].include?('Sociopath')
  return false if org['prohibitedOwnerTraits'].include?('Sociopath')
end

def faction_unique?(org)
  org['restricted'].select { |fac| fac.length > 0 }.length == 7
end

def restricted(org)
  ideologies = {
    'Alien': 'Alien',
    'Appease': 'Protectorate',
    'Cooperate': 'Academy',
    'Escape': 'Exodus',
    'Resist': 'Resistance',
    'Destroy': 'HF',
    'Exploit': 'Initiative',
    'Submit': 'Servants'
  }
  bans = org['restricted'].select { |b| b.length > 1 }.map { |b| ideologies[b.to_sym] }
  bans.map { |b| "* #{b}"}.join("\n")
end

generate_table()
