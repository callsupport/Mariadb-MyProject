#!/bin/bash

# Assurer que le script est exécutable
chmod +x "$0"

# Fonction pour générer un mot de passe aléatoire de 16 caractères
generate_password() {
    if command -v openssl &> /dev/null; then
        openssl rand -base64 16
    else
        < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16
    fi
}

# Vérifier le gestionnaire de paquets du système
if command -v apt-get &> /dev/null; then
    package_manager="apt-get"
elif command -v dnf &> /dev/null; then
    package_manager="dnf"
elif command -v yum &> /dev/null; then
    package_manager="yum"
else
    echo "Gestionnaire de paquets non pris en charge. Veuillez installer MariaDB manuellement."
    exit 1
fi

# Installer MariaDB
sudo $package_manager update
sudo $package_manager install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Demander le nom du projet s'il n'est pas fourni en argument
if [ -z "$1" ]; then
    read -p "Veuillez entrer le nom du projet : " project_name
else
    project_name="$1"
fi

# Générer un mot de passe aléatoire
password=$(generate_password)

# Créer la base de données
sudo mysql -e "CREATE DATABASE $project_name;"

# Créer un utilisateur et lui attribuer le mot de passe aléatoire
sudo mysql -e "CREATE USER '$project_name'@'localhost' IDENTIFIED BY '$password';"

# Accorder tous les droits à l'utilisateur sur la base de données
sudo mysql -e "GRANT ALL PRIVILEGES ON $project_name.* TO '$project_name'@'localhost';"

# Afficher les informations récapitulatives
echo "Base de données créée avec succès:"
echo "Nom du projet : $project_name"
echo "Nom d'utilisateur : $project_name"
echo "Mot de passe : $password"

# Enregistrez ces informations dans un fichier si nécessaire
echo -e "Nom du projet : $project_name\nNom d'utilisateur : $project_name\nMot de passe : $password" > "$project_name"_database_info.txt
