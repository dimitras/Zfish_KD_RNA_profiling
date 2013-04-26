# USAGE:
# ruby phosphorylated_list.rb ../data/KD/F001745_KD-ALL_with_pipes.csv 100.0 30.0 ../results/KD_unique_prot_and_phospho_pep.xlsx

# ruby phosphorylated_list.rb ../data/RNA/F001746_RNA-ALL_with_pipes.csv 100.0 30.0 ../results/RNA_unique_prot_and_phospho_pep.xlsx

# ruby phosphorylated_list.rb ../data/WT/F001671_with_pipes.csv 100.0 30.0 ../results/WT_unique_prot_and_phospho_pep.xlsx

# mascot csv to Tilo's format
require 'rubygems'
require 'axlsx'
require 'mascot_hits_csv_parser'

infile = ARGV[0]
pep_expectancy_cutoff = ARGV[1].to_f
pep_score_cutoff = ARGV[2].to_f
tilos_list_ofile = ARGV[3]

# initialize arguments
mascot_csvp = MascotHitsCSVParser.open(infile, pep_expectancy_cutoff, pep_score_cutoff)
tilos_list = Axlsx::Package.new
wb = tilos_list.workbook
# add some styles to the worksheet
header = wb.styles.add_style :b => true, :alignment => { :horizontal => :left }
alignment = wb.styles.add_style :alignment => { :horizontal => :left }

# get the unique proteins (get the highest scored protein that has pep_score >= 30)
unique_proteins = {}
mascot_csvp.each_protein do |protein|
	highest_scored_hit_per_protein = mascot_csvp.highest_from_cutoff_scored_hit_for_prot(protein)
	if !highest_scored_hit_per_protein.nil?
		unique_proteins[protein] = highest_scored_hit_per_protein
	end
end

# create sheet1 - proteins list
wb.add_worksheet(:name => "Unique Proteins") do |sheet|
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH"], :style=>header
	unique_proteins.each do |protein, hit|
		prot_hit_num = hit.prot_hit_num.to_i
		prot_acc = hit.prot_acc.to_s
		uniprot_link = "http://www.uniprot.org/uniprot/#{prot_acc}"
		prot_desc = hit.prot_desc.to_s
		if prot_desc.include? "GN="
			genename = prot_desc.split("GN=")[1].split(" ")[0].to_s
		else
			genename = 'NA'
		end
		prot_score = hit.prot_score.to_f
		prot_mass = hit.prot_mass.to_i
		prot_matches_sig = hit.prot_matches_sig.to_f
		prot_matches = hit.prot_matches.to_i

		row = sheet.add_row [prot_hit_num, prot_acc, uniprot_link, genename, prot_desc, prot_score, prot_mass, prot_matches_sig, prot_matches], :style=>alignment
		sheet.add_hyperlink :location => uniprot_link, :ref => "C#{row.index + 1}"
		sheet["C#{row.index + 1}"].color = "0000FF"
	end
end


# get the highest scored hit of each peptide, with rank = 1 and Phospho modified
# 2 Phospho (ST); Phospho (Y)  
# Phospho (ST); 2 Phospho (Y)
# Phospho (ST)
# 3 Phospho (ST)
# 3 Oxidation (M); 2 Phospho (ST)
highest_scored_hits = {}
mascot_csvp.each_peptide do |peptide|
	highest_scored_hit = mascot_csvp.highest_scored_hit_for_pep(peptide)
	highest_scored_hits[peptide] = highest_scored_hit
end

# create sheet 2 - peptides list
wb.add_worksheet(:name => "Potential Phosphorylations") do |sheet|
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH", "QUERY", "PEP_SCORE", "PEP_EXPECTANCY", "PEP_SEQ", "PEP_MODIFICATION", "TITLE"], :style=>header
	highest_scored_hits.each do |peptide, highest_scored_hit|
		prot_hit_num = highest_scored_hit.prot_hit_num.to_i
		prot_acc = highest_scored_hit.prot_acc.to_s
		uniprot_link = "http://www.uniprot.org/uniprot/#{prot_acc}"
		prot_desc = highest_scored_hit.prot_desc.to_s
		if prot_desc.include? "GN="
			genename = prot_desc.split("GN=")[1].split(" ")[0].to_s
		else
			genename = 'NA'
		end
		prot_score = highest_scored_hit.prot_score.to_f
		prot_mass = highest_scored_hit.prot_mass.to_i
		prot_matches_sig = highest_scored_hit.prot_matches_sig.to_f
		prot_matches = highest_scored_hit.prot_matches.to_i
		query = highest_scored_hit.pep_query.to_s
		pep_score = highest_scored_hit.pep_score.to_f
		pep_expect = highest_scored_hit.pep_expect.to_f
		pep_seq = highest_scored_hit.pep_seq.to_s
		pep_var_mod = highest_scored_hit.pep_var_mod.to_s
		pep_scan_title = highest_scored_hit.pep_scan_title.to_s

		row = sheet.add_row [prot_hit_num, prot_acc, uniprot_link, genename, prot_desc, prot_score, prot_mass, prot_matches_sig, prot_matches, query, pep_score, pep_expect, pep_seq, pep_var_mod, pep_scan_title], :style=>alignment
		sheet.add_hyperlink :location => uniprot_link, :ref => "C#{row.index + 1}"
		sheet["C#{row.index + 1}"].color = "0000FF"
	end
end


# write an xlsx file
tilos_list.serialize(tilos_list_ofile)


