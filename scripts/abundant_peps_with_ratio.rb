# USAGE:
# ruby abundant_peps_with_ratio.rb ../data/KD/F001745_KD-ALL_with_pipes.csv ../data/RNA/F001746_RNA-ALL_with_pipes.csv 100.0 0.0 ../results/KD_unique_proteins.xlsx ../results/RNA_unique_proteins.xlsx ../results/KD-RNA_unique_proteins_and_differential_expression.xlsx

# ruby abundant_peps_with_ratio.rb ../data/KD/F001745_KD-ALL_with_pipes.csv ../data/RNA/F001746_RNA-ALL_with_pipes.csv 100.0 30.0 ../results/KD-RNA/KD_unique_proteins_with_cutoff.xlsx ../results/KD-RNA/RNA_unique_proteins_with_cutoff.xlsx ../results/KD-RNA/KD-RNA_unique_proteins_and_differential_expression_with_cutoff.xlsx

# ruby abundant_peps_with_ratio.rb ../data/WT/F001671_with_pipes.csv ../data/RNA/F001746_RNA-ALL_with_pipes.csv 100.0 30.0 ../results/WT-RNA/WT_unique_proteins_with_cutoff.xlsx ../results/WT-RNA/RNA_unique_proteins_with_cutoff.xlsx ../results/WT-RNA/WT-RNA_unique_proteins_and_differential_expression_with_cutoff.xlsx

# ruby abundant_peps_with_ratio.rb ../data/WT/F001671_with_pipes.csv ../data/KD/F001745_KD-ALL_with_pipes.csv 100.0 30.0 ../results/WT-KD/WT_unique_proteins_with_cutoff.xlsx ../results/WT-KD/KD_unique_proteins_with_cutoff.xlsx ../results/WT-KD/WT-KD_unique_proteins_and_differential_expression_with_cutoff.xlsx

# mascot csv to Tilo's format & calculate the ratio for the total and significant matched peptides between the KO vs RNA (and sort by logratio?)
require 'rubygems'
require 'axlsx'
require 'mascot_hits_csv_parser'

ko_infile = ARGV[0]
rna_infile = ARGV[1]
pep_expectancy_cutoff = ARGV[2].to_f
pep_score_cutoff = ARGV[3].to_f
ko_unique_proteins_ofile = ARGV[4]
rna_unique_proteins_ofile = ARGV[5]
tilos_list_ofile = ARGV[6]

#######################################
# initialize arguments
#######################################

ko_mascot_csvp = MascotHitsCSVParser.open(ko_infile, pep_expectancy_cutoff, pep_score_cutoff)
rna_mascot_csvp = MascotHitsCSVParser.open(rna_infile, pep_expectancy_cutoff, pep_score_cutoff)

################################################
# make the lists for uniques and common proteins
################################################

# get the unique proteins of KD (get the highest scored protein that has pep_score >= pep_score_cutoff)
ko_unique_proteins = {}
ko_mascot_csvp.each_protein do |protein|
	highest_scored_hit_per_protein = ko_mascot_csvp.highest_from_cutoff_scored_hit_for_prot(protein)
	if !highest_scored_hit_per_protein.nil?
		ko_unique_proteins[protein] = highest_scored_hit_per_protein
	end
end

puts "KD proteins identified"

# get the unique proteins of RNA (get the highest scored protein that has pep_score >= pep_score_cutoff)
rna_unique_proteins = {}
rna_mascot_csvp.each_protein do |protein|
	highest_scored_hit_per_protein = rna_mascot_csvp.highest_from_cutoff_scored_hit_for_prot(protein)
	if !highest_scored_hit_per_protein.nil?
		rna_unique_proteins[protein] = highest_scored_hit_per_protein
	end
end

puts "RNA proteins identified"

# get the common proteins between the experiments KD and RNA
common_proteins = Hash.new { |h,k| h[k] = [] }
rna_unique_proteins.each do |protein, hit|
	if ko_unique_proteins.include?(protein)
		common_proteins[protein] = [ko_unique_proteins[protein], rna_unique_proteins[protein]]
	end
end

puts "Common proteins identified"

#######################################
# TABLE1: all proteins identified in KD
#######################################

# output
ko_unique_proteins_xlsx = Axlsx::Package.new
ko_unique_proteins_wb = ko_unique_proteins_xlsx.workbook
# add some styles to the worksheet		
ko_header = ko_unique_proteins_wb.styles.add_style :b => true, :alignment => { :horizontal => :left }
ko_alignment = ko_unique_proteins_wb.styles.add_style :alignment => { :horizontal => :left }

# create sheet1 - proteins list
# ko_unique_proteins_wb.add_worksheet(:name => "KD Unique Proteins") do |sheet|
ko_unique_proteins_wb.add_worksheet(:name => "WT Unique Proteins") do |sheet|
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH"], :style=>ko_header
	ko_unique_proteins.each do |protein, hit|
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

		row = sheet.add_row [prot_hit_num, prot_acc, uniprot_link, genename, prot_desc, prot_score, prot_mass, prot_matches_sig, prot_matches], :style=>ko_alignment
		sheet.add_hyperlink :location => uniprot_link, :ref => "C#{row.index + 1}"
		sheet["C#{row.index + 1}"].color = "0000FF"
	end
end

# write xlsx file
ko_unique_proteins_xlsx.serialize(ko_unique_proteins_ofile)

puts "TABLE1 ready"

#######################################
# TABLE2: all proteins identified in RNA
#######################################

# output
rna_unique_proteins_xlsx = Axlsx::Package.new
rna_unique_proteins_wb = rna_unique_proteins_xlsx.workbook
# add some styles to the worksheet		
rna_header = rna_unique_proteins_wb.styles.add_style :b => true, :alignment => { :horizontal => :left }
rna_alignment = rna_unique_proteins_wb.styles.add_style :alignment => { :horizontal => :left }

# create sheet2 - proteins list
# rna_unique_proteins_wb.add_worksheet(:name => "RNA Unique Proteins") do |sheet|
rna_unique_proteins_wb.add_worksheet(:name => "KD Unique Proteins") do |sheet|
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH"], :style=>rna_header
	rna_unique_proteins.each do |protein, hit|
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

		row = sheet.add_row [prot_hit_num, prot_acc, uniprot_link, genename, prot_desc, prot_score, prot_mass, prot_matches_sig, prot_matches], :style=>rna_alignment
		sheet.add_hyperlink :location => uniprot_link, :ref => "C#{row.index + 1}"
		sheet["C#{row.index + 1}"].color = "0000FF"
	end
end

# write xlsx file
rna_unique_proteins_xlsx.serialize(rna_unique_proteins_ofile)

puts "TABLE2 ready"

#####################################################
# TABLE3: all proteins identified in KD but not in RNA 
# && all proteins identified in RNA but not in KD 
# && differential expression log ratios
#####################################################

# output
tilos_list_xlsx = Axlsx::Package.new
tilos_list_wb = tilos_list_xlsx.workbook
# add some styles to the worksheet		
header = tilos_list_wb.styles.add_style :b => true, :alignment => { :horizontal => :left }
alignment = tilos_list_wb.styles.add_style :alignment => { :horizontal => :left }

# create sheet1 - all proteins identified in KD but not in RNA
# tilos_list_wb.add_worksheet(:name => "KD-only Unique Proteins") do |sheet|
tilos_list_wb.add_worksheet(:name => "WT-only Unique Proteins") do |sheet|	
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH"], :style=>header
	ko_unique_proteins.each do |protein, hit|
		if !common_proteins.include?(protein)
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
end

# create sheet2 - all proteins identified in RNA but not in ko
# tilos_list_wb.add_worksheet(:name => "RNA-only Unique Proteins") do |sheet|
tilos_list_wb.add_worksheet(:name => "KD-only Unique Proteins") do |sheet|
	sheet.add_row ["PROT_HIT_NUM", "PROT_ACC", "UNIPROT_LINK", "GENENAME", "PROT_DESC", "PROT_SCORE", "PROT_MASS", "PROT_MATCH_SIG", "PROT_MATCH"], :style=>header
	rna_unique_proteins.each do |protein, hit|
		if !common_proteins.include?(protein)
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
end

# create sheet3 - ratios
# tilos_list_wb.add_worksheet(:name => "KD-RNA differential expression") do |sheet|
# 	sheet.add_row ["PROT_ACC", "UNIPROT_LINK", "PROT_DESC", "KD PROT_HIT_NUM", "RNA PROT_HIT_NUM", "KD PROT_SCORE", "RNA PROT_SCORE", "KD PROT_MATCH_SIG", "RNA PROT_MATCH_SIG", "PROT_MATCH_SIG RNA:KD", "LOG(PROT_MATCH_SIG RNA:KD)", "KD PROT_MATCH", "RNA PROT_MATCH", "PROT_MATCH RNA:KD", "LOG(PROT_MATCH RNA:KD)"], :style=>header
# tilos_list_wb.add_worksheet(:name => "WT-RNA differential expression") do |sheet|
# 	sheet.add_row ["PROT_ACC", "UNIPROT_LINK", "PROT_DESC", "WT PROT_HIT_NUM", "RNA PROT_HIT_NUM", "WT PROT_SCORE", "RNA PROT_SCORE", "WT PROT_MATCH_SIG", "RNA PROT_MATCH_SIG", "PROT_MATCH_SIG RNA:WT", "LOG(PROT_MATCH_SIG RNA:WT)", "WT PROT_MATCH", "RNA PROT_MATCH", "PROT_MATCH RNA:WT", "LOG(PROT_MATCH RNA:WT)"], :style=>header
tilos_list_wb.add_worksheet(:name => "WT-KD differential expression") do |sheet|
	sheet.add_row ["PROT_ACC", "UNIPROT_LINK", "PROT_DESC", "WT PROT_HIT_NUM", "KD PROT_HIT_NUM", "WT PROT_SCORE", "KD PROT_SCORE", "WT PROT_MATCH_SIG", "KD PROT_MATCH_SIG", "PROT_MATCH_SIG KD:WT", "LOG(PROT_MATCH_SIG KD:WT)", "WT PROT_MATCH", "KD PROT_MATCH", "PROT_MATCH KD:WT", "LOG(PROT_MATCH KD:WT)"], :style=>header
	common_proteins.each do |protein, hits|
		uniprot_link = "http://www.uniprot.org/uniprot/#{protein}"
		prot_desc = hits[0].prot_desc.to_s
		ko_prot_hit_num = hits[0].prot_hit_num.to_i
		rna_prot_hit_num = hits[1].prot_hit_num.to_i
		ko_prot_score = hits[0].prot_score.to_f
		rna_prot_score = hits[1].prot_score.to_f
		ko_prot_matches_sig = hits[0].prot_matches_sig.to_f
		rna_prot_matches_sig = hits[1].prot_matches_sig.to_f
		if rna_prot_matches_sig != 0.0 && ko_prot_matches_sig != 0.0
			ratio_sig = (rna_prot_matches_sig/ko_prot_matches_sig).to_f
			logratio_sig = Math::log(ratio_sig)
		else
			logratio_sig = ""
		end
		ko_prot_matches = hits[0].prot_matches.to_f
		rna_prot_matches = hits[1].prot_matches.to_f
		if rna_prot_matches != 0.0 && ko_prot_matches != 0.0 # there is no need for this check
			ratio_total = (rna_prot_matches/ko_prot_matches).to_f
			logratio_total = Math::log(ratio_total)
		else
			logratio_total = ""
		end

		row = sheet.add_row [protein, uniprot_link, prot_desc, ko_prot_hit_num, rna_prot_hit_num, ko_prot_score, rna_prot_score, ko_prot_matches_sig, rna_prot_matches_sig, rna_prot_matches_sig.to_s+":"+ko_prot_matches_sig.to_s, logratio_sig, ko_prot_matches, rna_prot_matches, rna_prot_matches.to_s+":"+ko_prot_matches.to_s, logratio_total], :style=>alignment
		sheet.add_hyperlink :location => uniprot_link, :ref => "B#{row.index + 1}"
		sheet["B#{row.index + 1}"].color = "0000FF"
	end
end

# write xlsx file
tilos_list_xlsx.serialize(tilos_list_ofile)

puts "TABLE3 ready"

