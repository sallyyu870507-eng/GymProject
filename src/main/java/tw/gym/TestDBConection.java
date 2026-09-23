package tw.gym;

import jakarta.persistence.EntityManager;
import jakarta.persistence.EntityManagerFactory;
import jakarta.persistence.Persistence;

public class TestDBConection {

	public static void main(String[] args) {
		 EntityManagerFactory emf =
	                Persistence.createEntityManagerFactory("gym");

	        EntityManager em = emf.createEntityManager();

	        System.out.println("資料庫連線成功");

	        em.close();
	        emf.close();
	}

}
