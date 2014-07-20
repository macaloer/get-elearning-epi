#!/usr/bin/perl -w
# Get-elearning-epitech.pl - Version 1.0.0
# Récupération des cours d'epitech
# Copyright (C) 2014 contact@macaloer.com

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use HTTP::Cookies;
use HTML::Form;
use HTML::TagParser;
use File::Fetch;
use Data::Types;
use threads;


our  $version = "1.0.0";
our  $copyright = "2014 macaloer.com";

my $path_backup = "./backup-epitech";
my $url_default = "https://intra.epitech.eu";
my $url_learning = "https://intra.epitech.eu/e-learning/";
my $url_data = "https://cdn.local.epitech.eu/elearning/";

########## Default number of thread  ##########
my $max_of_threads = 4;
########## Default number of thread ##########

sub vSleep {

    local $| = 1;
    my $sleepTime = 5;

    print("Sleeping for $sleepTime seconds...\n");
    my $i=$sleepTime;
    while ($i>0) {
        print "$i... ";
        $i=$i-1;
        sleep(1);
    }
    print("\n\n");
}


sub initThreads {  
  
    my @tab_threads;

    for(my $i = 0;$i<=$max_of_threads;$i++){
      push(@tab_threads,$i);
    }
    return @tab_threads;
}

sub get_html_link_data {

    my $html = HTML::TagParser->new("elearning.html");
    my @list = $html->getElementsByTagName("a");
    my $href;
    my $data;
    my @tab;

    foreach my $elem (@list) {
        my $tagname = $elem->tagName;
        my $attr = $elem->attributes;
        my $text = $elem->innerText;

        foreach my $key (sort keys %$attr) {
            if ($key eq "href" and $key ne "") {
                $href = "$attr->{$key} \n";
                if ($href =~ m"#!/semester") {
                    push (@tab, $href);
                }
            } elsif ($key eq "data-value") {
                    $data = "$attr->{$key} \n";
                    push (@tab, $data);
            }
        }
    }
    return @tab;
}

sub get_login_password {

    print "Your login    : ";
    my $login = <>;
    chomp $login;

    print "Your password : ";
    my $password = <>; 
    chomp $password;

    print "\nDefault threads : 2 / Max threads : 8 \n\n";
    print "Number of threads: ";
    $max_of_threads  = <>; 
    chomp $max_of_threads;

#   if ((my $bool = is_int($max_of_threads)) == "true") {
 #       if ($max_of_threads >= 8) {
   #         $max_of_threads = 8;
  #    } elsif ($max_of_threads <= 0) {
    #        $max_of_threads = 2;
     # }
   # } else {
    #    print "Info : Please enter number beetween 2 and 8 !\n";
     #   exit 0;
   # }

    my %hash = ("login", $login, "password", $password);
    print "\n";
    return %hash;
}

sub check_login {

    my $log = "";
    my $len = length($log);

    if ($len == 8) {
        if ($log =~ /_/) {
            return 1;
      } else {
          return 0;
        }
      } else {
        return 0;
      }
}

sub connect_to_epi {

    my %hash = get_login_password();

    my $ua = LWP::UserAgent->new(
              agent      => 'Chrome/34.0.1847.116',
              ssl_opts => { verify_hostname => 1 },
              cookie_jar => HTTP::Cookies->new(
              file           => "Cooki_epitech",
              autosave       => 0,
              ignore_discard => 1,
              )
    );

    $ua->protocols_allowed(['https']);
    $ua->timeout(3);
    #$ua->proxy( 'http', 'http://proxy.example.com:3128/');

    my $get_html = $ua->get($url_default);
    my $form = HTML::Form->parse($get_html->content, $url_default);

    $form->value('login' => $hash{login});
    $form->value('password' => $hash{password});
    
    $ua->request($form->click);
    $get_html = $ua->get($url_learning);

    if ($get_html->is_success) {
        print "Info : Vous etes connecter a epitech\n";

       if (open(FIC, ">elearning.html")) {
           #binmode FIC, ':encoding(UTF-8)';
           print FIC $get_html->decoded_content;
        } else {
            print "Erreur : Impossible de crer elearning.html";
            exit 0;
        }
        create_path_and_dl(get_html_link_data());
    } else {
        print "Erreur : Impossible de se connecter a l'url : intra.epitech.eu !\n";
        print "Info   : Verifier votre password !\n\n";
        exit 0;
    }
}

sub download {

    my @tab = @_;
    my $id = threads->tid();
    my $http="http";
    my $data = substr($tab[1], 5);
    my $data_final = "${http}${data}";

    chomp($data_final);
    $tab[0] =~ s/^\s+//; 
    $tab[0] =~ s/\s+$//;
    my $ff = File::Fetch->new(uri => $data_final);
    my $where = $ff->fetch(to => $tab[0]) or die $ff->error;
    threads->exit();
}

sub create_path_and_dl(\@) {

    my @tab = @_;
    my @abc;
    my $semester;
    my $category;
    my $cour;
    my $other;
    my $url_data;
    my $path;
    my $tab_len;

    my @threads_init = initThreads();
    my @thread_run;
    my $thr;

    my $len = scalar(@tab);
    my $i = 0;

    print "tab = $len\n";

    while ($i <= $len) {
          if ($tab[$i] =~ m"#!/") {
              @abc = split (/\//, $tab[$i]);
              $tab_len = scalar (@abc);
              if ($tab_len >= 2) { 
                  $semester = $abc[1];
                  if ($semester ne "") {
                      $path ="$path_backup/$semester";
                  } if ($tab_len >= 3) {
                      $category = $abc[2];
                      if ($category ne "") {
                          $path ="$path_backup/$semester/$category/";
                      } if ($tab_len >= 4) {
                          $cour = $abc[3];
                          if ($cour ne "") {
                              $path ="$path_backup/$semester/$category/$cour";
                          } if ($tab_len >= 5) {
                              $other = $abc[4];
                              if ($other ne "") {
                                $path ="$path_backup/$semester/$category/$cour$other";
                              }
                          } 
                      } 
                  }
              }
          } elsif ($tab[$i] =~ m"cdn.local.epitech.eu") {

              @thread_run = threads->list(threads::running);
              if (scalar @thread_run < $max_of_threads) {

                  $thr = threads->new(\&download, $path, $tab[$i]);
                  push (@threads_init, $thr->tid);
                  @thread_run = threads->list(threads::running);

              } elsif (scalar @thread_run >= $max_of_threads) {
                  while (scalar @thread_run >= $max_of_threads) {
                        @thread_run = threads->list(threads::running);
                  }
                }
            }
          $i++;
    } 

    @thread_run = threads->list(threads::running);

    while (scalar @thread_run != 0) {
          foreach my $thr (@threads_init) {
              $thr->join if ($thr->is_joinable());
          }
          @thread_run = threads->list(threads::running);
    }
}

sub main {

    print "\n Start : Get-Elearning-Epitech !\n\n";
    connect_to_epi();
}

main();
