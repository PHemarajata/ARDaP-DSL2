process PHYLOGENY {
    label 'ardap_default'
    publishDir "./Outputs/Phylogeny_and_annotation", mode: 'copy', overwrite: true
    
    input:
    path matrix
    
    output:
    path "*.newick", emit: tree
    path "*.png", emit: tree_plot, optional: true
    
    script:
    """
    FastTree -nt -gtr ${matrix} > phylogenetic_tree.newick
    
    # Optional: create a simple tree plot if R is available
    if command -v Rscript &> /dev/null; then
        Rscript - <<'EOF'
        if (require(ape, quietly=TRUE) && require(png, quietly=TRUE)) {
            tree <- read.tree("phylogenetic_tree.newick")
            png("phylogenetic_tree.png", width=800, height=600)
            plot(tree, main="Phylogenetic Tree")
            dev.off()
        }
EOF
    fi
    """
    
    stub:
    """
    touch phylogenetic_tree.newick
    touch phylogenetic_tree.png
    """
}