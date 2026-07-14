package com.example;

public class App {
    public static void main(String[] args) throws InterruptedException {
        System.out.println("Java GitOps App running successfully inside Amazon EKS!");
        
        while (true) {
            System.out.println("Application heartbeat check: OK");
            Thread.sleep(60000); 
        }
    }
}
