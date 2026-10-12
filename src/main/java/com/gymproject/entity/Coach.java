package com.gymproject.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "coach", schema = "dbo")
@Getter
@Setter
public class Coach {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coachid")
    private Integer coachid;

    @Column(name = "accountid")
    private Integer accountid;

    @Column(name = "coachno", nullable = false,
            unique = true, length = 20)
    private String coachno;

    @Nationalized
    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Nationalized
    @Column(name = "gender", length = 10)
    private String gender;

    @Column(name = "phone", length = 20)
    private String phone;

    @Column(name = "email", length = 100)
    private String email;

    @Nationalized
    @Column(name = "specialty", length = 200)
    private String specialty;

    @Nationalized
    @Column(name = "status", nullable = false, length = 20)
    private String status = "在職";
}